///|
suberror TestFlushError {
  TestFlushError(String)
}

///|
async test "shutdown drains pending records" {
  inspect(
    async_runtime_mode_label(async_runtime_mode()) == "native_worker" ||
    async_runtime_mode_label(async_runtime_mode()) == "compatibility",
    content="true",
  )
  let written : Ref[Array[String]] = Ref([])
  let flushes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) { written.val.push(rec.message) }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      max_batch=4,
      linger_ms=10,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.test",
    flush=fn(_) {
      flushes.val += 1
      ()
    },
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("one")
    logger.info("two")
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.has_failed(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(
    match logger.flush_policy() {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Batch",
  )
  inspect(written.val.length(), content="2")
  inspect(written.val[0], content="one")
  inspect(written.val[1], content="two")
  inspect(flushes.val, content="1")
}

///|
async test "close clear counts abandoned records as dropped" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.clear",
  )

  logger.info("one")
  logger.info("two")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="0")
  logger.close(clear=true)
  inspect(logger.is_closed(), content="true")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="2")
}

///|
async test "shutdown clear closes without worker startup" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.noworker",
  )

  logger.info("one")
  logger.shutdown(clear=true)
  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
async test "closed blocking logger does not add pending count on later log attempts" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.closed.blocking",
  )

  logger.info("one")
  logger.close(clear=true)
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")

  logger.info("late")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
async test "closed logger runtime determines whether later log reaches patch path" {
  let patched : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.closed.patch",
  ).with_patch(fn(rec) {
    patched.val += 1
    rec
  })

  logger.info("one")
  inspect(patched.val, content="1")
  logger.close(clear=true)
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")

  logger.info("late")
  inspect(patched.val, content="1")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
async test "closed logger does not enter filter path on later log attempts" {
  let filtered : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.closed.filter",
  ).with_filter(fn(_) {
    filtered.val += 1
    true
  })

  logger.info("one")
  inspect(filtered.val, content="1")
  logger.close(clear=true)

  logger.info("late")
  inspect(filtered.val, content="1")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
async test "run rejects duplicate worker startup for same logger" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.run.duplicate",
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    while !logger.is_running() {
      @async.pause()
    }

    let second_error = (async fn() -> String {
      logger.run()
      "no error"
    })() catch {
      err => err.to_string()
    }

    inspect(second_error.contains("AsyncLoggerAlreadyRunning"), content="true")
    let state = logger.state()
    inspect(
      match state.phase {
        AsyncLifecyclePhase::Running => "running"
        _ => "other"
      },
      content="running",
    )
    inspect(logger.has_failed(), content="false")
    inspect(logger.last_error(), content="")
    inspect(state.can_rerun, content="false")
    inspect(state.terminal, content="false")
    logger.shutdown(clear=true)
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "async logger with_filter composes and leaves base logger unchanged" {
  let written_targets : Ref[Array[String]] = Ref([])
  let written_messages : Ref[Array[String]] = Ref([])
  let base = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      written_targets.val.push(rec.target)
      written_messages.val.push(rec.message)
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Trace,
    target="service",
  )
  let filtered = base.with_filter(
    @bitlogger.all_of([
      @bitlogger.target_has_prefix("service.api"),
      @bitlogger.level_at_least(@bitlogger.Level::Info),
      @bitlogger.message_contains("visible"),
    ]),
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => filtered.run())
    filtered.debug("visible debug")
    filtered.info("hidden info")
    filtered.child("api").info("visible info")
    filtered.shutdown()
  })

  inspect(written_messages.val.length(), content="1")
  inspect(written_messages.val[0], content="visible info")
  inspect(written_targets.val[0], content="service.api")

  let base_written : Ref[Array[String]] = Ref([])
  let untouched = async_logger(
    @bitlogger.callback_sink(fn(rec) { base_written.val.push(rec.message) }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="base",
  )
  ignore(untouched.with_filter(fn(_) { false }))

  @async.with_task_group(group => {
    group.spawn_bg(() => untouched.run())
    untouched.info("base still writes")
    untouched.shutdown()
  })

  inspect(base_written.val.length(), content="1")
  inspect(base_written.val[0], content="base still writes")
}

///|
async test "async logger with_patch composes before filter and does not mutate base logger" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger = async_logger(
      @bitlogger.callback_sink(fn(rec) {
        captured_target.val = rec.target
        captured_message.val = rec.message
        captured_fields.val = rec.fields
      }),
      config=AsyncLoggerConfig::new(max_pending=4),
      min_level=@bitlogger.Level::Info,
      target="auth",
    )
    .with_patch(
      @bitlogger.compose_patches([
        @bitlogger.set_target("audit.auth"),
        @bitlogger.prefix_message("[safe] "),
        @bitlogger.redact_field("token"),
        @bitlogger.append_fields([@bitlogger.field("service", "bitlogger")]),
      ]),
    )
    .with_filter(@bitlogger.target_is("audit.auth"))

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("login", fields=[
      @bitlogger.field("token", "secret"),
      @bitlogger.field("user", "alice"),
    ])
    logger.shutdown()
  })

  inspect(captured_target.val, content="audit.auth")
  inspect(captured_message.val, content="[safe] login")
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].key, content="token")
  inspect(captured_fields.val[0].value, content="***")
  inspect(captured_fields.val[1].key, content="user")
  inspect(captured_fields.val[1].value, content="alice")
  inspect(captured_fields.val[2].key, content="service")
  inspect(captured_fields.val[2].value, content="bitlogger")

  let base_message : Ref[String] = Ref("")
  let base_target : Ref[String] = Ref("")
  let base_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let base = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      base_message.val = rec.message
      base_target.val = rec.target
      base_fields.val = rec.fields
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="auth",
  )
  ignore(base.with_patch(@bitlogger.prefix_message("[safe] ")))

  @async.with_task_group(group => {
    group.spawn_bg(() => base.run())
    base.info("plain", fields=[@bitlogger.field("token", "secret")])
    base.shutdown()
  })

  inspect(base_target.val, content="auth")
  inspect(base_message.val, content="plain")
  inspect(base_fields.val.length(), content="1")
  inspect(base_fields.val[0].value, content="secret")
}

///|
async test "async logger with_min_level only affects derived logger threshold" {
  let base_written : Ref[Array[String]] = Ref([])
  let derived_written : Ref[Array[String]] = Ref([])
  let base = async_logger(
    @bitlogger.callback_sink(fn(rec) { base_written.val.push(rec.message) }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="level.base",
  )
  let derived = async_logger(
    @bitlogger.callback_sink(fn(rec) { derived_written.val.push(rec.message) }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="level.derived",
  ).with_min_level(@bitlogger.Level::Error)

  inspect(base.is_enabled(@bitlogger.Level::Info), content="true")
  inspect(derived.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(derived.is_enabled(@bitlogger.Level::Error), content="true")

  @async.with_task_group(group => {
    group.spawn_bg(() => base.run())
    group.spawn_bg(() => derived.run())
    base.info("base info")
    derived.info("derived info skipped")
    derived.error("derived error kept")
    base.shutdown()
    derived.shutdown()
  })

  inspect(base_written.val.length(), content="1")
  inspect(base_written.val[0], content="base info")
  inspect(derived_written.val.length(), content="1")
  inspect(derived_written.val[0], content="derived error kept")
}

///|
async test "async logger with_target replaces default target without mutating base logger" {
  let written_targets : Ref[Array[String]] = Ref([])
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) { written_targets.val.push(rec.target) }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.base",
  ).with_timestamp()
  let retargeted = logger.with_target("async.retarget")

  inspect(logger.target, content="async.base")
  inspect(retargeted.target, content="async.retarget")
  inspect(logger.timestamp, content="true")
  inspect(retargeted.timestamp, content="true")

  @async.with_task_group(group => {
    group.spawn_bg(() => retargeted.run())
    retargeted.error("retargeted")
    retargeted.shutdown()
  })

  inspect(written_targets.val.length(), content="1")
  inspect(written_targets.val[0], content="async.retarget")

  let base_targets : Ref[Array[String]] = Ref([])
  let base = async_logger(
    @bitlogger.callback_sink(fn(rec) { base_targets.val.push(rec.target) }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.base",
  )
  ignore(base.with_target("async.retarget"))

  @async.with_task_group(group => {
    group.spawn_bg(() => base.run())
    base.error("base")
    base.shutdown()
  })

  inspect(base_targets.val.length(), content="1")
  inspect(base_targets.val[0], content="async.base")
}

///|
async test "async logger with_context_fields prepends shared fields without mutating base logger" {
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) { written_fields.val = rec.fields }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.ctx",
  )
  let contextual = logger.with_context_fields([
    @bitlogger.field("service", "bitlogger"),
    @bitlogger.field("scope", "sdk"),
  ])

  inspect(logger.context_fields.length(), content="0")
  inspect(contextual.context_fields.length(), content="2")

  @async.with_task_group(group => {
    group.spawn_bg(() => contextual.run())
    contextual.error("ctx", fields=[@bitlogger.field("mode", "test")])
    contextual.shutdown()
  })

  inspect(written_fields.val.length(), content="3")
  inspect(written_fields.val[0].key, content="service")
  inspect(written_fields.val[0].value, content="bitlogger")
  inspect(written_fields.val[1].key, content="scope")
  inspect(written_fields.val[1].value, content="sdk")
  inspect(written_fields.val[2].key, content="mode")
  inspect(written_fields.val[2].value, content="test")
}

///|
async test "async logger child composes target and preserves other state" {
  let written_target : Ref[String] = Ref("")
  let written_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      written_target.val = rec.target
      written_timestamp.val = rec.timestamp_ms
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="sdk",
  ).with_timestamp()
  let child = logger.child("worker")

  inspect(logger.target, content="sdk")
  inspect(child.target, content="sdk.worker")
  inspect(child.timestamp, content="true")
  inspect(child.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(child.is_enabled(@bitlogger.Level::Info), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => child.run())
    child.error("child")
    child.shutdown()
  })

  inspect(written_target.val, content="sdk.worker")
  inspect(written_timestamp.val > 0UL, content="true")

  let root_child = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="",
  ).child("worker")
  inspect(root_child.target, content="worker")

  let keep_parent = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="sdk",
  ).child("")
  inspect(keep_parent.target, content="sdk")
}

///|
async test "async logger with_timestamp only affects derived logger timestamp flag" {
  let base_timestamp : Ref[UInt64] = Ref(0UL)
  let derived_timestamp : Ref[UInt64] = Ref(0UL)
  let base = async_logger(
    @bitlogger.callback_sink(fn(rec) { base_timestamp.val = rec.timestamp_ms }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.ts.base",
  )
  let derived = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      derived_timestamp.val = rec.timestamp_ms
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.ts.derived",
  ).with_timestamp()

  inspect(base.timestamp, content="false")
  inspect(derived.timestamp, content="true")

  @async.with_task_group(group => {
    group.spawn_bg(() => base.run())
    group.spawn_bg(() => derived.run())
    base.error("base")
    derived.error("derived")
    base.shutdown()
    derived.shutdown()
  })

  inspect(base_timestamp.val, content="0")
  inspect(derived_timestamp.val > 0UL, content="true")
}

///|
async test "async logger log supports per-call target override" {
  let written_target : Ref[String] = Ref("")
  let written_message : Ref[String] = Ref("")
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      written_target.val = rec.target
      written_message.val = rec.message
      written_fields.val = rec.fields
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.default",
  ).with_context_fields([@bitlogger.field("service", "bitlogger")])

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      fields=[@bitlogger.field("mode", "test")],
      target="async.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.override")
  inspect(written_message.val, content="override")
  inspect(written_fields.val.length(), content="2")
  inspect(written_fields.val[0].key, content="service")
  inspect(written_fields.val[0].value, content="bitlogger")
  inspect(written_fields.val[1].key, content="mode")
  inspect(written_fields.val[1].value, content="test")

  let second_target : Ref[String] = Ref("")
  let second_message : Ref[String] = Ref("")
  let second_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let second = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      second_target.val = rec.target
      second_message.val = rec.message
      second_fields.val = rec.fields
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.default",
  ).with_context_fields([@bitlogger.field("service", "bitlogger")])

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.log(@bitlogger.Level::Error, "default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.default")
  inspect(second_message.val, content="default")
  inspect(second_fields.val.length(), content="1")
  inspect(second_fields.val[0].key, content="service")
}

///|
async test "async logger severity helpers use stored target without override" {
  let written_levels : Ref[Array[String]] = Ref([])
  let written_targets : Ref[Array[String]] = Ref([])
  let written_fields : Ref[Array[Array[@bitlogger.Field]]] = Ref([])
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      written_levels.val.push(rec.level.label())
      written_targets.val.push(rec.target)
      written_fields.val.push(rec.fields)
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="async.helpers",
  ).with_context_fields([@bitlogger.field("service", "bitlogger")])

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("info", fields=[@bitlogger.field("mode", "info")])
    logger.warn("warn", fields=[@bitlogger.field("mode", "warn")])
    logger.error("error", fields=[@bitlogger.field("mode", "error")])
    logger.shutdown()
  })

  inspect(written_levels.val.length(), content="3")
  inspect(written_levels.val[0], content="INFO")
  inspect(written_levels.val[1], content="WARN")
  inspect(written_levels.val[2], content="ERROR")
  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.helpers")
  inspect(written_targets.val[1], content="async.helpers")
  inspect(written_targets.val[2], content="async.helpers")
  inspect(written_fields.val[0].length(), content="2")
  inspect(written_fields.val[1].length(), content="2")
  inspect(written_fields.val[2].length(), content="2")
  inspect(written_fields.val[0][0].key, content="service")
  inspect(written_fields.val[0][1].value, content="info")
  inspect(written_fields.val[1][0].key, content="service")
  inspect(written_fields.val[1][1].value, content="warn")
  inspect(written_fields.val[2][0].key, content="service")
  inspect(written_fields.val[2][1].value, content="error")
}

///|
test "async logger config stringify roundtrips stable fields" {
  let text = stringify_async_logger_config(
    AsyncLoggerConfig::new(
      max_pending=8,
      overflow=AsyncOverflowPolicy::DropOldest,
      max_batch=3,
      linger_ms=25,
      flush=AsyncFlushPolicy::Batch,
    ),
  )
  let config = parse_async_logger_config_text(text)
  inspect(config.max_pending, content="8")
  inspect(config.max_batch, content="3")
  inspect(config.linger_ms, content="25")
  inspect(
    match config.overflow {
      AsyncOverflowPolicy::Blocking => "Blocking"
      AsyncOverflowPolicy::DropOldest => "DropOldest"
      AsyncOverflowPolicy::DropNewest => "DropNewest"
    },
    content="DropOldest",
  )
  inspect(
    match config.flush {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Batch",
  )
}

///|
test "async logger config parser accepts compatibility aliases" {
  let config = parse_async_logger_config_text(
    "{\"overflow\":\"DropLatest\",\"flush\":\"None\",\"max_batch\":0,\"linger_ms\":-2}",
  )
  inspect(config.max_batch, content="1")
  inspect(config.linger_ms, content="0")
  inspect(
    match config.overflow {
      AsyncOverflowPolicy::Blocking => "Blocking"
      AsyncOverflowPolicy::DropOldest => "DropOldest"
      AsyncOverflowPolicy::DropNewest => "DropNewest"
    },
    content="DropNewest",
  )
  inspect(
    match config.flush {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Never",
  )
}

///|
async test "async logger config constructor normalizes batch and linger but preserves pending input" {
  let config = AsyncLoggerConfig::new(
    max_pending=-3,
    overflow=AsyncOverflowPolicy::DropNewest,
    max_batch=0,
    linger_ms=-5,
    flush=AsyncFlushPolicy::Batch,
  )
  inspect(config.max_pending, content="-3")
  inspect(config.max_batch, content="1")
  inspect(config.linger_ms, content="0")
  inspect(
    match config.overflow {
      AsyncOverflowPolicy::Blocking => "Blocking"
      AsyncOverflowPolicy::DropOldest => "DropOldest"
      AsyncOverflowPolicy::DropNewest => "DropNewest"
    },
    content="DropNewest",
  )
  inspect(
    match config.flush {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Batch",
  )

  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config~,
    min_level=@bitlogger.Level::Info,
    target="async.config.normalized",
  )
  logger.info("one")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
test "async build config stringify roundtrips nested logger and async fields" {
  let text = stringify_async_logger_build_config(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.roundtrip",
        timestamp=true,
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::TextConsole),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropNewest,
        max_batch=5,
        linger_ms=40,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )
  let config = parse_async_logger_build_config_text(text)
  inspect(config.logger.min_level.label(), content="WARN")
  inspect(config.logger.target, content="async.roundtrip")
  inspect(config.logger.timestamp, content="true")
  inspect(config.async_config.max_pending, content="2")
  inspect(config.async_config.max_batch, content="5")
  inspect(config.async_config.linger_ms, content="40")
  inspect(
    match config.async_config.overflow {
      AsyncOverflowPolicy::Blocking => "Blocking"
      AsyncOverflowPolicy::DropOldest => "DropOldest"
      AsyncOverflowPolicy::DropNewest => "DropNewest"
    },
    content="DropNewest",
  )
  inspect(
    match config.async_config.flush {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )
}

///|
test "async build config parser fills omitted sections from defaults" {
  let config = parse_async_logger_build_config_text("{}")
  inspect(config.logger.min_level.label(), content="INFO")
  inspect(config.logger.target, content="")
  inspect(config.logger.timestamp, content="false")
  inspect(
    match config.logger.sink.kind {
      @bitlogger.SinkKind::Console => "Console"
      @bitlogger.SinkKind::JsonConsole => "JsonConsole"
      @bitlogger.SinkKind::TextConsole => "TextConsole"
      @bitlogger.SinkKind::File => "File"
    },
    content="Console",
  )
  inspect(config.logger.queue is None, content="true")
  inspect(config.async_config.max_pending, content="0")
  inspect(config.async_config.max_batch, content="1")
  inspect(config.async_config.linger_ms, content="0")
  inspect(
    match config.async_config.overflow {
      AsyncOverflowPolicy::Blocking => "Blocking"
      AsyncOverflowPolicy::DropOldest => "DropOldest"
      AsyncOverflowPolicy::DropNewest => "DropNewest"
    },
    content="Blocking",
  )
  inspect(
    match config.async_config.flush {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Never",
  )
}

///|
test "async json helpers export stable structured shapes" {
  let config_json = async_logger_config_to_json(
    AsyncLoggerConfig::new(
      max_pending=8,
      overflow=AsyncOverflowPolicy::DropOldest,
      max_batch=3,
      linger_ms=25,
      flush=AsyncFlushPolicy::Batch,
    ),
  )
  let config_obj = config_json.as_object().unwrap()
  inspect(
    @json_parser.stringify(config_json),
    content="{\"max_pending\":8,\"max_batch\":3,\"linger_ms\":25,\"overflow\":\"DropOldest\",\"flush\":\"Batch\"}",
  )
  inspect(
    config_obj.get("max_pending").unwrap().as_number().unwrap().to_int(),
    content="8",
  )
  inspect(
    config_obj.get("max_batch").unwrap().as_number().unwrap().to_int(),
    content="3",
  )
  inspect(
    config_obj.get("linger_ms").unwrap().as_number().unwrap().to_int(),
    content="25",
  )
  inspect(
    config_obj.get("overflow").unwrap().as_string().unwrap(),
    content="DropOldest",
  )
  inspect(
    config_obj.get("flush").unwrap().as_string().unwrap(),
    content="Batch",
  )

  let build_json = async_logger_build_config_to_json(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.roundtrip",
        timestamp=true,
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::TextConsole),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropNewest,
        max_batch=5,
        linger_ms=40,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )
  let build_obj = build_json.as_object().unwrap()
  let logger_obj = build_obj.get("logger").unwrap().as_object().unwrap()
  let sink_obj = logger_obj.get("sink").unwrap().as_object().unwrap()
  let formatter_obj = sink_obj
    .get("text_formatter")
    .unwrap()
    .as_object()
    .unwrap()
  let async_obj = build_obj.get("async_config").unwrap().as_object().unwrap()

  inspect(
    logger_obj.get("min_level").unwrap().as_string().unwrap(),
    content="WARN",
  )
  inspect(
    logger_obj.get("target").unwrap().as_string().unwrap(),
    content="async.roundtrip",
  )
  inspect(
    logger_obj.get("timestamp").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(logger_obj.get("queue") is None, content="true")
  inspect(
    sink_obj.get("kind").unwrap().as_string().unwrap(),
    content="text_console",
  )
  inspect(sink_obj.get("path").unwrap().as_string().unwrap(), content="")
  inspect(sink_obj.get("append").unwrap().as_bool().unwrap(), content="true")
  inspect(
    sink_obj.get("auto_flush").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("separator").unwrap().as_string().unwrap(),
    content=" ",
  )
  inspect(
    formatter_obj.get("field_separator").unwrap().as_string().unwrap(),
    content=" ",
  )
  inspect(
    formatter_obj.get("template").unwrap().as_string().unwrap(),
    content="",
  )
  inspect(
    formatter_obj.get("color_mode").unwrap().as_string().unwrap(),
    content="never",
  )
  inspect(
    formatter_obj.get("color_support").unwrap().as_string().unwrap(),
    content="truecolor",
  )
  inspect(
    formatter_obj.get("style_markup").unwrap().as_string().unwrap(),
    content="full",
  )
  inspect(
    async_obj.get("max_pending").unwrap().as_number().unwrap().to_int(),
    content="2",
  )
  inspect(
    async_obj.get("max_batch").unwrap().as_number().unwrap().to_int(),
    content="5",
  )
  inspect(
    async_obj.get("linger_ms").unwrap().as_number().unwrap().to_int(),
    content="40",
  )
  inspect(
    async_obj.get("overflow").unwrap().as_string().unwrap(),
    content="DropNewest",
  )
  inspect(
    async_obj.get("flush").unwrap().as_string().unwrap(),
    content="Shutdown",
  )
}

///|
test "async build config json export materializes parsed omitted defaults" {
  let parsed = parse_async_logger_build_config_text("{}")
  let build_json = async_logger_build_config_to_json(parsed)
  let build_obj = build_json.as_object().unwrap()
  let logger_obj = build_obj.get("logger").unwrap().as_object().unwrap()
  let sink_obj = logger_obj.get("sink").unwrap().as_object().unwrap()
  let formatter_obj = sink_obj
    .get("text_formatter")
    .unwrap()
    .as_object()
    .unwrap()
  let async_obj = build_obj.get("async_config").unwrap().as_object().unwrap()

  inspect(
    @json_parser.stringify(build_json),
    content="{\"logger\":{\"min_level\":\"INFO\",\"target\":\"\",\"timestamp\":false,\"sink\":{\"kind\":\"console\",\"path\":\"\",\"append\":true,\"auto_flush\":true,\"text_formatter\":{\"show_timestamp\":true,\"show_level\":true,\"show_target\":true,\"show_fields\":true,\"separator\":\" \",\"field_separator\":\" \",\"template\":\"\",\"color_mode\":\"never\",\"color_support\":\"truecolor\",\"style_markup\":\"full\",\"target_style_markup\":\"disabled\",\"fields_style_markup\":\"disabled\"}}},\"async_config\":{\"max_pending\":0,\"max_batch\":1,\"linger_ms\":0,\"overflow\":\"Blocking\",\"flush\":\"Never\"}}",
  )
  inspect(
    logger_obj.get("min_level").unwrap().as_string().unwrap(),
    content="INFO",
  )
  inspect(logger_obj.get("target").unwrap().as_string().unwrap(), content="")
  inspect(
    logger_obj.get("timestamp").unwrap().as_bool().unwrap(),
    content="false",
  )
  inspect(logger_obj.get("queue") is None, content="true")
  inspect(sink_obj.get("kind").unwrap().as_string().unwrap(), content="console")
  inspect(sink_obj.get("path").unwrap().as_string().unwrap(), content="")
  inspect(sink_obj.get("append").unwrap().as_bool().unwrap(), content="true")
  inspect(
    sink_obj.get("auto_flush").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_level").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_target").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_fields").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("separator").unwrap().as_string().unwrap(),
    content=" ",
  )
  inspect(
    formatter_obj.get("field_separator").unwrap().as_string().unwrap(),
    content=" ",
  )
  inspect(
    formatter_obj.get("template").unwrap().as_string().unwrap(),
    content="",
  )
  inspect(
    formatter_obj.get("color_mode").unwrap().as_string().unwrap(),
    content="never",
  )
  inspect(
    formatter_obj.get("color_support").unwrap().as_string().unwrap(),
    content="truecolor",
  )
  inspect(
    formatter_obj.get("style_markup").unwrap().as_string().unwrap(),
    content="full",
  )
  inspect(
    formatter_obj.get("target_style_markup").unwrap().as_string().unwrap(),
    content="disabled",
  )
  inspect(
    formatter_obj.get("fields_style_markup").unwrap().as_string().unwrap(),
    content="disabled",
  )
  inspect(formatter_obj.get("style_tags") is None, content="true")
  inspect(
    async_obj.get("max_pending").unwrap().as_number().unwrap().to_int(),
    content="0",
  )
  inspect(
    async_obj.get("max_batch").unwrap().as_number().unwrap().to_int(),
    content="1",
  )
  inspect(
    async_obj.get("linger_ms").unwrap().as_number().unwrap().to_int(),
    content="0",
  )
  inspect(
    async_obj.get("overflow").unwrap().as_string().unwrap(),
    content="Blocking",
  )
  inspect(async_obj.get("flush").unwrap().as_string().unwrap(), content="Never")
}

///|
test "async config parsers reject malformed input" {
  let invalid_json_error = (fn() -> String raise {
    ignore(parse_async_logger_config_text("{"))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(invalid_json_error.contains("UnexpectedToken"), content="true")

  let wrong_type_error = (fn() -> String raise {
    ignore(parse_async_logger_config_text("{\"max_pending\":\"many\"}"))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(
    wrong_type_error.contains("Expected number at async_config.max_pending"),
    content="true",
  )

  let invalid_enum_error = (fn() -> String raise {
    ignore(parse_async_logger_config_text("{\"overflow\":\"Burst\"}"))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(
    invalid_enum_error.contains("Unsupported async overflow policy: Burst"),
    content="true",
  )

  let invalid_build_root_error = (fn() -> String raise {
    ignore(parse_async_logger_build_config_text("[]"))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(
    invalid_build_root_error.contains(
      "Expected object at async logger build config root",
    ),
    content="true",
  )

  let nested_sync_error = (fn() -> String raise {
    ignore(
      parse_async_logger_build_config_text(
        "{\"logger\":{\"timestamp\":\"true\"}}",
      ),
    )
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(
    nested_sync_error.contains("ConfigError.InvalidConfig"),
    content="true",
  )
}

///|
test "async runtime capability helpers stay consistent" {
  let mode = async_runtime_mode()
  let state = async_runtime_state()
  let worker_supported = match mode {
    AsyncRuntimeMode::NativeWorker => true
    AsyncRuntimeMode::Compatibility => false
  }
  inspect(
    async_runtime_mode_label(mode) == "native_worker" ||
    async_runtime_mode_label(mode) == "compatibility",
    content="true",
  )
  inspect(
    async_runtime_supports_background_worker() == worker_supported,
    content="true",
  )
  inspect(
    async_runtime_mode_label(state.mode) == async_runtime_mode_label(mode),
    content="true",
  )
  inspect(state.background_worker == worker_supported, content="true")
  inspect(
    @json_parser.stringify(async_runtime_state_to_json(state)),
    content=if worker_supported {
      "{\"mode\":\"native_worker\",\"background_worker\":true}"
    } else {
      "{\"mode\":\"compatibility\",\"background_worker\":false}"
    },
  )
  inspect(
    stringify_async_runtime_state(state),
    content=if worker_supported {
      "{\"mode\":\"native_worker\",\"background_worker\":true}"
    } else {
      "{\"mode\":\"compatibility\",\"background_worker\":false}"
    },
  )
}

///|
test "async runtime mode and worker flag encode target contract" {
  let mode_label = async_runtime_mode_label(async_runtime_mode())
  let worker = async_runtime_supports_background_worker()
  inspect(
    mode_label == "native_worker" || mode_label == "compatibility",
    content="true",
  )
  inspect((mode_label == "native_worker") == worker, content="true")
  inspect((mode_label == "compatibility") == !worker, content="true")
}

///|
test "async logger state snapshot reflects current counters and runtime" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=3,
      overflow=AsyncOverflowPolicy::DropNewest,
      flush=AsyncFlushPolicy::Shutdown,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.state",
  )
  let state = logger.state()
  inspect(
    async_runtime_mode_label(state.runtime.mode) ==
    async_runtime_mode_label(async_runtime_mode()),
    content="true",
  )
  inspect(
    state.runtime.background_worker ==
    async_runtime_supports_background_worker(),
    content="true",
  )
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(
    match state.phase {
      AsyncLifecyclePhase::Ready => "ready"
      AsyncLifecyclePhase::Running => "running"
      AsyncLifecyclePhase::Failed => "failed"
      AsyncLifecyclePhase::Closing => "closing"
      AsyncLifecyclePhase::Closed => "closed"
      AsyncLifecyclePhase::ClosedFailed => "closed_failed"
    },
    content="ready",
  )
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(state.backlog_retained, content="false")
  inspect(state.can_rerun, content="true")
  inspect(state.terminal, content="false")
  inspect(state.last_error, content="")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )
  inspect(
    @json_parser.stringify(async_logger_state_to_json(state)),
    content=if async_runtime_supports_background_worker() {
      "{\"runtime\":{\"mode\":\"native_worker\",\"background_worker\":true},\"phase\":\"ready\",\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"backlog_retained\":false,\"can_rerun\":true,\"terminal\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    } else {
      "{\"runtime\":{\"mode\":\"compatibility\",\"background_worker\":false},\"phase\":\"ready\",\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"backlog_retained\":false,\"can_rerun\":true,\"terminal\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    },
  )
  inspect(
    stringify_async_logger_state(state),
    content=if async_runtime_supports_background_worker() {
      "{\"runtime\":{\"mode\":\"native_worker\",\"background_worker\":true},\"phase\":\"ready\",\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"backlog_retained\":false,\"can_rerun\":true,\"terminal\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    } else {
      "{\"runtime\":{\"mode\":\"compatibility\",\"background_worker\":false},\"phase\":\"ready\",\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"backlog_retained\":false,\"can_rerun\":true,\"terminal\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    },
  )
}

///|
async test "async logger state enters running phase while worker is active" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(max_pending=2),
    min_level=@bitlogger.Level::Info,
    target="async.state.running",
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    while !logger.is_running() {
      @async.pause()
    }

    let state = logger.state()
    inspect(
      match state.phase {
        AsyncLifecyclePhase::Running => "running"
        _ => "other"
      },
      content="running",
    )
    inspect(state.is_closed, content="false")
    inspect(state.is_running, content="true")
    inspect(state.has_failed, content="false")
    inspect(state.backlog_retained, content="false")
    inspect(state.can_rerun, content="false")
    inspect(state.terminal, content="false")
    logger.shutdown(clear=true)
  })
}

///|
async test "run drains queued records in compatibility backends too" {
  let written : Ref[Array[String]] = Ref([])
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) { written.val.push(rec.message) }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::DropNewest,
      max_batch=2,
      linger_ms=5,
      flush=AsyncFlushPolicy::Never,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.compat",
  )

  @async.with_task_group(group => {
    logger.info("one")
    logger.info("two")
    inspect(logger.pending_count(), content="2")
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.pending_count(), content="0")
  inspect(written.val.length(), content="2")
  inspect(written.val[0], content="one")
  inspect(written.val[1], content="two")
}

///|
async test "async logger records worker failures and wait_idle stops early" {
  let writes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) { writes.val += 1 }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.failure",
    flush=fn(_) -> Unit raise { raise TestFlushError("flush exploded") },
  )

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    logger.info("ok")
    logger.info("flush-now")
    logger.wait_idle()
    inspect(logger.has_failed(), content="true")
    inspect(logger.pending_count(), content="1")
    logger.close(clear=true)
  })

  inspect(writes.val, content="1")
  inspect(logger.has_failed(), content="true")
  inspect(logger.last_error().contains("TestFlushError"), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")

  let state = logger.state()
  inspect(
    match state.phase {
      AsyncLifecyclePhase::ClosedFailed => "closed_failed"
      _ => "other"
    },
    content="closed_failed",
  )
  inspect(state.backlog_retained, content="false")
  inspect(state.can_rerun, content="false")
  inspect(state.terminal, content="true")
}

///|
async test "later started run resets async failure state before draining remaining backlog" {
  let writes : Ref[Int] = Ref(0)
  let flushes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) { writes.val += 1 }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.retry",
    flush=fn(_) -> Unit raise {
      flushes.val += 1
      if flushes.val == 1 {
        raise TestFlushError("flush exploded once")
      }
      ()
    },
  )

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    logger.info("one")
    logger.info("two")
    logger.wait_idle()
    inspect(logger.has_failed(), content="true")
    inspect(logger.last_error().contains("TestFlushError"), content="true")
    inspect(logger.is_running(), content="false")
    inspect(logger.pending_count(), content="1")

    let failed_state = logger.state()
    inspect(
      match failed_state.phase {
        AsyncLifecyclePhase::Failed => "failed"
        _ => "other"
      },
      content="failed",
    )
    inspect(failed_state.backlog_retained, content="true")
    inspect(failed_state.can_rerun, content="true")
    inspect(failed_state.terminal, content="false")

    group.spawn_bg(() => logger.run())
    while !logger.is_running() {
      @async.pause()
    }
    inspect(logger.has_failed(), content="false")
    inspect(logger.last_error(), content="")

    let running_state = logger.state()
    inspect(
      match running_state.phase {
        AsyncLifecyclePhase::Running => "running"
        _ => "other"
      },
      content="running",
    )
    logger.shutdown()
  })

  inspect(writes.val, content="2")
  inspect(flushes.val, content="2")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
  inspect(logger.is_running(), content="false")
  inspect(logger.is_closed(), content="true")
  inspect(logger.pending_count(), content="0")
}

///|
async test "shutdown after worker failure clears remaining pending backlog" {
  let writes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) { writes.val += 1 }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.failure.shutdown",
    flush=fn(_) -> Unit raise {
      raise TestFlushError("flush exploded on shutdown path")
    },
  )

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    logger.info("one")
    logger.info("two")
    logger.wait_idle()
    inspect(logger.has_failed(), content="true")
    inspect(logger.pending_count(), content="1")
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.has_failed(), content="true")
  inspect(logger.last_error().contains("TestFlushError"), content="true")
  inspect(logger.is_running(), content="false")
  inspect(writes.val, content="1")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")

  let state = logger.state()
  inspect(
    match state.phase {
      AsyncLifecyclePhase::ClosedFailed => "closed_failed"
      _ => "other"
    },
    content="closed_failed",
  )
  inspect(state.is_closed, content="true")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="true")
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="1")
  inspect(state.backlog_retained, content="false")
  inspect(state.can_rerun, content="false")
  inspect(state.terminal, content="true")
}

///|
async test "shutdown clear reaches terminal closed phase without worker startup" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.shutdown.clear.state",
  )

  logger.info("one")
  logger.shutdown(clear=true)

  let state = logger.state()
  inspect(
    match state.phase {
      AsyncLifecyclePhase::Closed => "closed"
      _ => "other"
    },
    content="closed",
  )
  inspect(state.is_closed, content="true")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="1")
  inspect(state.backlog_retained, content="false")
  inspect(state.can_rerun, content="false")
  inspect(state.terminal, content="true")
}

///|
async test "library async logger keeps a smaller async facade" {
  let written_targets : Ref[Array[String]] = Ref([])
  let written_messages : Ref[Array[String]] = Ref([])
  let written_field_counts : Ref[Array[Int]] = Ref([])
  let logger = LibraryAsyncLogger::new(
      @bitlogger.callback_sink(fn(rec) {
        written_targets.val.push(rec.target)
        written_messages.val.push(rec.message)
        written_field_counts.val.push(rec.fields.length())
      }),
      config=AsyncLoggerConfig::new(max_pending=4),
      min_level=@bitlogger.Level::Info,
      target="async.lib",
    )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .child("worker")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("ready", fields=[@bitlogger.field("mode", "test")])
    logger.shutdown()
  })

  inspect(written_targets.val.length(), content="1")
  inspect(written_targets.val[0], content="async.lib.worker")
  inspect(written_messages.val[0], content="ready")
  inspect(written_field_counts.val[0], content="2")
}

///|
async test "library async new preserves config and flush failure contract" {
  let writes : Ref[Int] = Ref(0)
  let flushes : Ref[Int] = Ref(0)
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) { writes.val += 1 }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      max_batch=3,
      linger_ms=7,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Warn,
    target="async.lib.new",
    flush=fn(_) -> Unit raise {
      flushes.val += 1
      raise TestFlushError("library new flush exploded")
    },
  )
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.new")
  inspect(
    match full.flush_policy() {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Batch",
  )
  inspect(full.pending_count(), content="0")
  inspect(full.has_failed(), content="false")
  inspect(full.last_error(), content="")

  logger.info("skip")
  inspect(full.pending_count(), content="0")
  logger.error("one")
  logger.error("two")
  inspect(full.pending_count(), content="2")

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    full.wait_idle()
    while !full.has_failed() && full.is_running() {
      @async.pause()
    }
    inspect(full.has_failed(), content="true")
    inspect(full.last_error().contains("TestFlushError"), content="true")
    inspect(full.is_running(), content="false")
    inspect(full.pending_count(), content="0")
    logger.shutdown(clear=true)
  })

  inspect(writes.val, content="2")
  inspect(flushes.val, content="1")
  inspect(full.is_closed(), content="true")
}

///|
async test "library async context binding replaces stored field set" {
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger = LibraryAsyncLogger::new(
      @bitlogger.callback_sink(fn(rec) { written_fields.val = rec.fields }),
      config=AsyncLoggerConfig::new(max_pending=4),
      min_level=@bitlogger.Level::Warn,
      target="async.lib.ctx",
    )
    .with_context_fields([@bitlogger.field("old", "gone")])
    .with_context_fields([
      @bitlogger.field("service", "bitlogger"),
      @bitlogger.field("scope", "sdk"),
    ])
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.ctx")
  inspect(full.timestamp, content="false")
  inspect(full.context_fields.length(), content="2")
  inspect(full.context_fields[0].key, content="service")
  inspect(full.context_fields[0].value, content="bitlogger")
  inspect(full.context_fields[1].key, content="scope")
  inspect(full.context_fields[1].value, content="sdk")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.error("ctx", fields=[@bitlogger.field("mode", "test")])
    logger.shutdown()
  })

  inspect(written_fields.val.length(), content="3")
  inspect(written_fields.val[0].key, content="service")
  inspect(written_fields.val[0].value, content="bitlogger")
  inspect(written_fields.val[1].key, content="scope")
  inspect(written_fields.val[1].value, content="sdk")
  inspect(written_fields.val[2].key, content="mode")
  inspect(written_fields.val[2].value, content="test")
}

///|
async test "library async bind matches context facade contract" {
  let written_target : Ref[String] = Ref("")
  let written_timestamp : Ref[UInt64] = Ref(0UL)
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger = async_logger(
      @bitlogger.callback_sink(fn(rec) {
        written_target.val = rec.target
        written_timestamp.val = rec.timestamp_ms
        written_fields.val = rec.fields
      }),
      config=AsyncLoggerConfig::new(max_pending=4),
      min_level=@bitlogger.Level::Warn,
      target="async.lib.bind",
    )
    .with_timestamp()
    .to_library_async_logger()
    .bind([@bitlogger.field("service", "bitlogger")])
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.bind")
  inspect(full.timestamp, content="true")
  inspect(full.context_fields.length(), content="1")
  inspect(full.context_fields[0].key, content="service")
  inspect(full.context_fields[0].value, content="bitlogger")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.error("bound", fields=[@bitlogger.field("mode", "test")])
    logger.shutdown()
  })

  inspect(written_target.val, content="async.lib.bind")
  inspect(written_timestamp.val > 0UL, content="true")
  inspect(written_fields.val.length(), content="2")
  inspect(written_fields.val[0].key, content="service")
  inspect(written_fields.val[0].value, content="bitlogger")
  inspect(written_fields.val[1].key, content="mode")
  inspect(written_fields.val[1].value, content="test")
}

///|
async test "library async logger with_target preserves facade state while replacing target" {
  let written_target : Ref[String] = Ref("")
  let written_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = async_logger(
      @bitlogger.callback_sink(fn(rec) {
        written_target.val = rec.target
        written_timestamp.val = rec.timestamp_ms
      }),
      config=AsyncLoggerConfig::new(max_pending=4),
      min_level=@bitlogger.Level::Warn,
      target="async.lib.base",
    )
    .with_timestamp()
    .to_library_async_logger()
    .with_target("async.lib.retarget")
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.retarget")
  inspect(full.timestamp, content="true")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="0")
  inspect(full.is_closed(), content="false")
  inspect(full.is_running(), content="false")
  inspect(full.has_failed(), content="false")
  inspect(full.last_error(), content="")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.error("retargeted")
    logger.shutdown()
  })

  inspect(written_target.val, content="async.lib.retarget")
  inspect(written_timestamp.val > 0UL, content="true")
}

///|
async test "library async logger child composes target through facade" {
  let written_target : Ref[String] = Ref("")
  let written_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = async_logger(
      @bitlogger.callback_sink(fn(rec) {
        written_target.val = rec.target
        written_timestamp.val = rec.timestamp_ms
      }),
      config=AsyncLoggerConfig::new(max_pending=4),
      min_level=@bitlogger.Level::Warn,
      target="sdk",
    )
    .with_timestamp()
    .to_library_async_logger()
    .child("worker")
  let full = logger.to_async_logger()

  inspect(full.target, content="sdk.worker")
  inspect(full.timestamp, content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.error("child")
    logger.shutdown()
  })

  inspect(written_target.val, content="sdk.worker")
  inspect(written_timestamp.val > 0UL, content="true")

  let root_child = LibraryAsyncLogger::new(@bitlogger.callback_sink(fn(_) {  })).child(
    "worker",
  )
  inspect(root_child.to_async_logger().target, content="worker")

  let keep_parent = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) {  }),
    target="sdk",
  ).child("")
  inspect(keep_parent.to_async_logger().target, content="sdk")
}

///|
async test "library async logger log supports per-call target override" {
  let written_target : Ref[String] = Ref("")
  let written_message : Ref[String] = Ref("")
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(rec) {
      written_target.val = rec.target
      written_message.val = rec.message
      written_fields.val = rec.fields
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.lib.default",
  ).with_context_fields([@bitlogger.field("service", "bitlogger")])

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      fields=[@bitlogger.field("mode", "test")],
      target="async.lib.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.lib.override")
  inspect(written_message.val, content="override")
  inspect(written_fields.val.length(), content="2")
  inspect(written_fields.val[0].key, content="service")
  inspect(written_fields.val[0].value, content="bitlogger")
  inspect(written_fields.val[1].key, content="mode")
  inspect(written_fields.val[1].value, content="test")

  let second_target : Ref[String] = Ref("")
  let second_message : Ref[String] = Ref("")
  let second_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let second = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(rec) {
      second_target.val = rec.target
      second_message.val = rec.message
      second_fields.val = rec.fields
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Warn,
    target="async.lib.default",
  ).with_context_fields([@bitlogger.field("service", "bitlogger")])

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.log(@bitlogger.Level::Error, "default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.lib.default")
  inspect(second_message.val, content="default")
  inspect(second_fields.val.length(), content="1")
  inspect(second_fields.val[0].key, content="service")
}

///|
async test "library async severity helpers use stored target without override" {
  let written_levels : Ref[Array[String]] = Ref([])
  let written_targets : Ref[Array[String]] = Ref([])
  let written_fields : Ref[Array[Array[@bitlogger.Field]]] = Ref([])
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(rec) {
      written_levels.val.push(rec.level.label())
      written_targets.val.push(rec.target)
      written_fields.val.push(rec.fields)
    }),
    config=AsyncLoggerConfig::new(max_pending=4),
    min_level=@bitlogger.Level::Info,
    target="async.lib.helpers",
  ).bind([@bitlogger.field("service", "bitlogger")])

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("info", fields=[@bitlogger.field("mode", "info")])
    logger.warn("warn", fields=[@bitlogger.field("mode", "warn")])
    logger.error("error", fields=[@bitlogger.field("mode", "error")])
    logger.shutdown()
  })

  inspect(written_levels.val.length(), content="3")
  inspect(written_levels.val[0], content="INFO")
  inspect(written_levels.val[1], content="WARN")
  inspect(written_levels.val[2], content="ERROR")
  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.lib.helpers")
  inspect(written_targets.val[1], content="async.lib.helpers")
  inspect(written_targets.val[2], content="async.lib.helpers")
  inspect(written_fields.val[0].length(), content="2")
  inspect(written_fields.val[1].length(), content="2")
  inspect(written_fields.val[2].length(), content="2")
  inspect(written_fields.val[0][0].key, content="service")
  inspect(written_fields.val[0][1].value, content="info")
  inspect(written_fields.val[1][0].key, content="service")
  inspect(written_fields.val[1][1].value, content="warn")
  inspect(written_fields.val[2][0].key, content="service")
  inspect(written_fields.val[2][1].value, content="error")
}

///|
async test "library async shutdown preserves wrapped failure cleanup semantics" {
  let writes : Ref[Int] = Ref(0)
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) { writes.val += 1 }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.lib.failure",
    flush=fn(_) -> Unit raise {
      raise TestFlushError("library facade flush exploded")
    },
  )
  let full = logger.to_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    logger.info("one")
    logger.info("two")
    full.wait_idle()
    inspect(full.has_failed(), content="true")
    inspect(full.pending_count(), content="1")
    logger.shutdown()
  })

  inspect(full.is_closed(), content="true")
  inspect(full.has_failed(), content="true")
  inspect(full.last_error().contains("TestFlushError"), content="true")
  inspect(full.is_running(), content="false")
  inspect(writes.val, content="1")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="1")
}

///|
async test "library async shutdown clear abandons pending records through facade" {
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.lib.clear",
  )
  let full = logger.to_async_logger()

  logger.info("one")
  inspect(full.pending_count(), content="1")
  inspect(full.dropped_count(), content="0")
  logger.shutdown(clear=true)
  inspect(full.is_closed(), content="true")
  inspect(full.is_running(), content="false")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="1")
}

///|
async test "library async logger can be built from config" {
  let logger = parse_and_build_library_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.config\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  let full = logger.to_async_logger()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.config")
}

///|
async test "library async builder unwrap matches direct async builder behavior" {
  let config = AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(
      min_level=@bitlogger.Level::Warn,
      target="async.lib.same-build",
      timestamp=true,
      queue=Some(
        @bitlogger.QueueConfig::new(
          3,
          overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
        ),
      ),
      sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
    ),
    async_config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::DropOldest,
      flush=AsyncFlushPolicy::Shutdown,
    ),
  )
  let logger = build_library_async_logger(config)
  let full = logger.to_async_logger()
  let direct = build_async_logger(config)
  let full_state = full.state()
  let direct_state = direct.state()

  inspect(full.target, content=direct.target)
  inspect(full.timestamp == direct.timestamp, content="true")
  inspect(
    logger.is_enabled(@bitlogger.Level::Error) ==
    direct.is_enabled(@bitlogger.Level::Error),
    content="true",
  )
  inspect(
    logger.is_enabled(@bitlogger.Level::Info) ==
    direct.is_enabled(@bitlogger.Level::Info),
    content="true",
  )
  inspect(
    stringify_async_logger_state(full_state) ==
    stringify_async_logger_state(direct_state),
    content="true",
  )
  let full_sink_kind = match full.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  let direct_sink_kind = match direct.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  inspect(full_sink_kind == direct_sink_kind, content="true")

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.dropped_count() == direct.dropped_count(), content="true")
  inspect(full.is_closed() == direct.is_closed(), content="true")
  inspect(full.is_running() == direct.is_running(), content="true")
  inspect(
    full.sink.pending_count() == direct.sink.pending_count(),
    content="true",
  )
  inspect(
    full.sink.dropped_count() == direct.sink.dropped_count(),
    content="true",
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    group.spawn_bg(() => direct.run())
    logger.shutdown()
    direct.shutdown()
  })

  inspect(full.is_closed() == direct.is_closed(), content="true")
  inspect(full.is_running() == direct.is_running(), content="true")
  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.dropped_count() == direct.dropped_count(), content="true")
  inspect(full.has_failed() == direct.has_failed(), content="true")
  inspect(full.last_error() == direct.last_error(), content="true")
}

///|
async test "library async builder log supports per-call target override through facade" {
  let written_target : Ref[String] = Ref("")

  let logger = build_library_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          min_level=@bitlogger.Level::Warn,
          target="async.lib.builder.default",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=2,
          overflow=AsyncOverflowPolicy::Blocking,
          flush=AsyncFlushPolicy::Never,
        ),
      ),
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      written_target.val = rec.target
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      target="async.lib.builder.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.lib.builder.override")

  let second_target : Ref[String] = Ref("")

  let second = build_library_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          min_level=@bitlogger.Level::Warn,
          target="async.lib.builder.default",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=2,
          overflow=AsyncOverflowPolicy::Blocking,
          flush=AsyncFlushPolicy::Never,
        ),
      ),
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      second_target.val = rec.target
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.error("default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.lib.builder.default")
}

///|
async test "library async builder severity helpers use stored target without override" {
  let written_targets : Ref[Array[String]] = Ref([])

  let logger = build_library_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          min_level=@bitlogger.Level::Trace,
          target="async.lib.builder.helpers",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=4,
          overflow=AsyncOverflowPolicy::Blocking,
          flush=AsyncFlushPolicy::Never,
        ),
      ),
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      written_targets.val.push(rec.target)
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("first")
    logger.warn("second")
    logger.error("third")
    logger.shutdown()
  })

  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.lib.builder.helpers")
  inspect(written_targets.val[1], content="async.lib.builder.helpers")
  inspect(written_targets.val[2], content="async.lib.builder.helpers")
}

///|
async test "library async builder shutdown clear abandons pending records through facade" {
  let logger = build_library_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Info,
        target="async.lib.builder.clear",
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
      ),
    ),
  )
  let full = logger.to_async_logger()

  logger.info("one")
  inspect(full.pending_count(), content="1")
  inspect(full.dropped_count(), content="0")
  logger.shutdown(clear=true)
  inspect(full.is_closed(), content="true")
  inspect(full.is_running(), content="false")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="1")
}

///|
async test "parsed library async logger unwrap keeps async helper surface" {
  let logger = parse_and_build_library_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.config.helpers\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropOldest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Shutdown\"}}",
  )
  let full = logger.to_async_logger()

  let state = full.state()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.config.helpers")
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(full.pending_count(), content="2")
  inspect(full.dropped_count(), content="1")
  inspect(full.is_closed(), content="false")
  inspect(full.is_running(), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(full.is_closed(), content="true")
  inspect(full.is_running(), content="false")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="1")
  inspect(full.has_failed(), content="false")
  inspect(full.last_error(), content="")
}

///|
async test "parsed library async logger shutdown clear abandons pending records through facade" {
  let logger = parse_and_build_library_async_logger(
    "{\"logger\":{\"min_level\":\"info\",\"target\":\"async.lib.json.clear\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  let full = logger.to_async_logger()

  logger.info("one")
  inspect(full.pending_count(), content="1")
  inspect(full.dropped_count(), content="0")
  logger.shutdown(clear=true)
  inspect(full.is_closed(), content="true")
  inspect(full.is_running(), content="false")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="1")
}

///|
async test "parsed library async logger log supports per-call target override through facade" {
  let written_target : Ref[String] = Ref("")

  let logger = parse_and_build_library_async_logger(
      "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.json.default\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      written_target.val = rec.target
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      target="async.lib.json.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.lib.json.override")

  let second_target : Ref[String] = Ref("")

  let second = parse_and_build_library_async_logger(
      "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.json.default\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      second_target.val = rec.target
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.error("default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.lib.json.default")
}

///|
async test "parsed library async severity helpers use stored target without override" {
  let written_targets : Ref[Array[String]] = Ref([])

  let logger = parse_and_build_library_async_logger(
      "{\"logger\":{\"min_level\":\"trace\",\"target\":\"async.lib.json.helpers.target\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":4,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      written_targets.val.push(rec.target)
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("first")
    logger.warn("second")
    logger.error("third")
    logger.shutdown()
  })

  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.lib.json.helpers.target")
  inspect(written_targets.val[1], content="async.lib.json.helpers.target")
  inspect(written_targets.val[2], content="async.lib.json.helpers.target")
}

///|
async test "library async parse-build unwrap matches parsed direct async builder behavior" {
  let raw = "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.json.same-build\",\"timestamp\":true,\"queue\":{\"max_pending\":3,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropOldest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Shutdown\"}}"
  let logger = parse_and_build_library_async_logger(raw)
  let full = logger.to_async_logger()
  let direct = build_async_logger(parse_async_logger_build_config_text(raw))
  let full_state = full.state()
  let direct_state = direct.state()

  inspect(full.target, content=direct.target)
  inspect(full.timestamp == direct.timestamp, content="true")
  inspect(
    logger.is_enabled(@bitlogger.Level::Error) ==
    direct.is_enabled(@bitlogger.Level::Error),
    content="true",
  )
  inspect(
    logger.is_enabled(@bitlogger.Level::Info) ==
    direct.is_enabled(@bitlogger.Level::Info),
    content="true",
  )
  inspect(
    stringify_async_logger_state(full_state) ==
    stringify_async_logger_state(direct_state),
    content="true",
  )
  let full_sink_kind = match full.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  let direct_sink_kind = match direct.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  inspect(full_sink_kind == direct_sink_kind, content="true")

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.dropped_count() == direct.dropped_count(), content="true")
  inspect(full.is_closed() == direct.is_closed(), content="true")
  inspect(full.is_running() == direct.is_running(), content="true")
  inspect(
    full.sink.pending_count() == direct.sink.pending_count(),
    content="true",
  )
  inspect(
    full.sink.dropped_count() == direct.sink.dropped_count(),
    content="true",
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    group.spawn_bg(() => direct.run())
    logger.shutdown()
    direct.shutdown()
  })

  inspect(full.is_closed() == direct.is_closed(), content="true")
  inspect(full.is_running() == direct.is_running(), content="true")
  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.dropped_count() == direct.dropped_count(), content="true")
  inspect(full.has_failed() == direct.has_failed(), content="true")
  inspect(full.last_error() == direct.last_error(), content="true")
}

///|
async test "library async parse-build unwrap preserves file-backed runtime helpers" {
  let raw = "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.json.file.same-build\",\"queue\":{\"max_pending\":3,\"overflow\":\"DropOldest\"},\"sink\":{\"kind\":\"file\",\"path\":\"async-lib-json-file-same-build.log\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropOldest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Shutdown\"}}"
  let logger = parse_and_build_library_async_logger(raw)
  let full = logger.to_async_logger()
  let direct = build_async_logger(parse_async_logger_build_config_text(raw))

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.dropped_count() == direct.dropped_count(), content="true")
  inspect(
    full.sink.pending_count() == direct.sink.pending_count(),
    content="true",
  )
  inspect(
    full.sink.dropped_count() == direct.sink.dropped_count(),
    content="true",
  )
  inspect(
    full.sink.file_available() == direct.sink.file_available(),
    content="true",
  )
  inspect(
    full.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    full.sink.file_auto_flush() == direct.sink.file_auto_flush(),
    content="true",
  )

  let full_state = full.sink.file_state()
  let direct_state = direct.sink.file_state()
  inspect(full_state.path == direct_state.path, content="true")
  inspect(full_state.available == direct_state.available, content="true")
  inspect(full_state.append == direct_state.append, content="true")
  inspect(full_state.auto_flush == direct_state.auto_flush, content="true")
  inspect(
    full_state.open_failures == direct_state.open_failures,
    content="true",
  )
  inspect(
    full_state.write_failures == direct_state.write_failures,
    content="true",
  )
  inspect(
    full_state.flush_failures == direct_state.flush_failures,
    content="true",
  )
  inspect(
    full_state.rotation_failures == direct_state.rotation_failures,
    content="true",
  )

  match (full.sink.file_runtime_state(), direct.sink.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(
    full.sink.file_set_append_mode(false) ==
    direct.sink.file_set_append_mode(false),
    content="true",
  )
  inspect(
    full.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    full.sink.file_set_auto_flush(false) ==
    direct.sink.file_set_auto_flush(false),
    content="true",
  )
  inspect(
    full.sink.file_auto_flush() == direct.sink.file_auto_flush(),
    content="true",
  )
  inspect(
    full.sink.file_set_rotation(
      Some(@bitlogger.file_rotation(36, max_backups=2)),
    ) ==
    direct.sink.file_set_rotation(
      Some(@bitlogger.file_rotation(36, max_backups=2)),
    ),
    content="true",
  )
  inspect(
    full.sink.file_rotation_enabled() == direct.sink.file_rotation_enabled(),
    content="true",
  )
  inspect(
    full.sink.file_reopen_append() == direct.sink.file_reopen_append(),
    content="true",
  )
  inspect(
    full.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    full.sink.file_clear_rotation() == direct.sink.file_clear_rotation(),
    content="true",
  )
  inspect(
    full.sink.file_reset_policy() == direct.sink.file_reset_policy(),
    content="true",
  )
  inspect(
    full.sink.file_policy_matches_default() ==
    direct.sink.file_policy_matches_default(),
    content="true",
  )
  inspect(
    full.sink.file_reset_failure_counters() ==
    direct.sink.file_reset_failure_counters(),
    content="true",
  )
  inspect(full.sink.file_flush() == direct.sink.file_flush(), content="true")
  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.sink.file_close() == direct.sink.file_close(), content="true")
}

///|
test "library async logger parse-and-build preserves parsed sync queue layer" {
  let logger = parse_and_build_library_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.config.queued\",\"queue\":{\"max_pending\":3,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.config.queued")
  inspect(
    match full.sink {
      @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
      @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
      @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
      @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
      _ => "Other"
    },
    content="QueuedConsole",
  )
}

///|
test "library async text logger can be built from typed config" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.lib.text",
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  let full = logger.to_async_logger()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.text")
}

///|
async test "library async text builder unwrap matches direct text builder behavior" {
  let config = AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(
      min_level=@bitlogger.Level::Warn,
      target="async.lib.text.same-build",
      timestamp=true,
      queue=Some(
        @bitlogger.QueueConfig::new(
          3,
          overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
        ),
      ),
      sink=@bitlogger.SinkConfig::new(
        kind=@bitlogger.SinkKind::TextConsole,
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
          template="TEXT:{target}:{message}",
        ),
      ),
    ),
    async_config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::DropOldest,
      flush=AsyncFlushPolicy::Shutdown,
    ),
  )
  let logger = build_library_async_text_logger(config)
  let full = logger.to_async_logger()
  let direct = build_async_text_logger(config)
  let full_state = full.state()
  let direct_state = direct.state()

  inspect(full.target, content=direct.target)
  inspect(full.timestamp == direct.timestamp, content="true")
  inspect(
    logger.is_enabled(@bitlogger.Level::Error) ==
    direct.is_enabled(@bitlogger.Level::Error),
    content="true",
  )
  inspect(
    logger.is_enabled(@bitlogger.Level::Info) ==
    direct.is_enabled(@bitlogger.Level::Info),
    content="true",
  )
  inspect(
    stringify_async_logger_state(full_state) ==
    stringify_async_logger_state(direct_state),
    content="true",
  )
  let record = @bitlogger.Record::new(
    @bitlogger.Level::Error,
    "boom",
    target="async.lib.text.same-build",
  )
  inspect(
    (full.sink.formatter)(record) == (direct.sink.formatter)(record),
    content="true",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.dropped_count() == direct.dropped_count(), content="true")
  inspect(full.is_closed() == direct.is_closed(), content="true")
  inspect(full.is_running() == direct.is_running(), content="true")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    group.spawn_bg(() => direct.run())
    logger.shutdown()
    direct.shutdown()
  })

  inspect(full.is_closed() == direct.is_closed(), content="true")
  inspect(full.is_running() == direct.is_running(), content="true")
  inspect(full.pending_count() == direct.pending_count(), content="true")
  inspect(full.dropped_count() == direct.dropped_count(), content="true")
  inspect(full.has_failed() == direct.has_failed(), content="true")
  inspect(full.last_error() == direct.last_error(), content="true")
}

///|
async test "library async text builder log supports per-call target override through facade" {
  let written_target : Ref[String] = Ref("")

  let logger = build_library_async_text_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.text_console(
          min_level=@bitlogger.Level::Warn,
          target="async.lib.text.builder.default",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=2,
          overflow=AsyncOverflowPolicy::Blocking,
          flush=AsyncFlushPolicy::Never,
        ),
      ),
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      written_target.val = rec.target
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      target="async.lib.text.builder.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.lib.text.builder.override")

  let second_target : Ref[String] = Ref("")

  let second = build_library_async_text_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.text_console(
          min_level=@bitlogger.Level::Warn,
          target="async.lib.text.builder.default",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=2,
          overflow=AsyncOverflowPolicy::Blocking,
          flush=AsyncFlushPolicy::Never,
        ),
      ),
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      second_target.val = rec.target
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.error("default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.lib.text.builder.default")
}

///|
async test "library async text builder severity helpers use stored target without override" {
  let written_targets : Ref[Array[String]] = Ref([])

  let logger = build_library_async_text_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.text_console(
          min_level=@bitlogger.Level::Info,
          target="async.lib.text.builder.helpers",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=4,
          overflow=AsyncOverflowPolicy::Blocking,
          flush=AsyncFlushPolicy::Never,
        ),
      ),
    )
    .to_async_logger()
    .with_patch(fn(rec) {
      written_targets.val.push(rec.target)
      rec
    })
    .to_library_async_logger()

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("first")
    logger.warn("second")
    logger.error("third")
    logger.shutdown()
  })

  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.lib.text.builder.helpers")
  inspect(written_targets.val[1], content="async.lib.text.builder.helpers")
  inspect(written_targets.val[2], content="async.lib.text.builder.helpers")
}

///|
async test "library async text logger unwrap keeps async helper surface" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.lib.text.helpers",
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropOldest,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )
  let full = logger.to_async_logger()

  let state = full.state()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.text.helpers")
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(full.pending_count(), content="2")
  inspect(full.dropped_count(), content="1")
  inspect(full.is_closed(), content="false")
  inspect(full.is_running(), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(full.is_closed(), content="true")
  inspect(full.is_running(), content="false")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="1")
  inspect(full.has_failed(), content="false")
  inspect(full.last_error(), content="")
}

///|
async test "library async text logger shutdown clear abandons pending records through facade" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Info,
        target="async.lib.text.clear",
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
      ),
    ),
  )
  let full = logger.to_async_logger()

  logger.info("one")
  inspect(full.pending_count(), content="1")
  inspect(full.dropped_count(), content="0")
  logger.shutdown(clear=true)
  inspect(full.is_closed(), content="true")
  inspect(full.is_running(), content="false")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="1")
}

///|
test "library async text logger builder ignores sync queue layer" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.lib.text.queued",
        queue=Some(
          @bitlogger.QueueConfig::new(
            3,
            overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
          ),
        ),
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.text.queued")
  inspect(full.pending_count(), content="0")
  inspect(full.dropped_count(), content="0")
}

///|
test "library async text logger ignores sink kind and still uses text formatter" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.lib.text.kind",
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::File,
          path="ignored.log",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
            template="TEXT:{target}:{message}",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.text.kind")
  let rendered = (full.sink.formatter)(
    @bitlogger.Record::new(
      @bitlogger.Level::Error,
      "boom",
      target="async.lib.text.kind",
    ),
  )
  inspect(rendered, content="TEXT:async.lib.text.kind:boom")
}

///|
async test "async logger can project to library async logger" {
  let logger = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        target="async.projected",
        min_level=@bitlogger.Level::Warn,
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  ).to_library_async_logger()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.to_async_logger().target, content="async.projected")
}

///|
async test "build async logger keeps direct helper surface and runtime sink path" {
  let logger = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.direct.helpers",
        queue=Some(
          @bitlogger.QueueConfig::new(
            3,
            overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
          ),
        ),
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropOldest,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )

  let state = logger.state()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.direct.helpers")
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )
  inspect(
    match logger.sink {
      @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
      @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
      @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
      @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
      _ => "Other"
    },
    content="QueuedConsole",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.is_closed(), content="false")
  inspect(logger.is_running(), content="false")
  inspect(logger.sink.pending_count(), content="0")
  inspect(logger.sink.dropped_count(), content="0")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
  inspect(logger.sink.pending_count(), content="0")
}

///|
async test "build async logger batch flush policy drains queued runtime sink work at batch boundary" {
  let logger = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Info,
        target="async.direct.batch.flush.runtime",
        queue=Some(
          @bitlogger.QueueConfig::new(
            4,
            overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
          ),
        ),
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=4,
        overflow=AsyncOverflowPolicy::Blocking,
        max_batch=2,
        flush=AsyncFlushPolicy::Batch,
      ),
    ),
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("one")
    logger.info("two")
    logger.wait_idle()
    inspect(logger.pending_count(), content="0")
    inspect(logger.sink.pending_count(), content="0")
    inspect(logger.has_failed(), content="false")
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.sink.pending_count(), content="0")
}

///|
async test "build async logger log supports per-call target override" {
  let written_target : Ref[String] = Ref("")

  let logger = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.builder.default",
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
        flush=AsyncFlushPolicy::Never,
      ),
    ),
  ).with_patch(fn(rec) {
    written_target.val = rec.target
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      target="async.builder.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.builder.override")

  let second_target : Ref[String] = Ref("")

  let second = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.builder.default",
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
        flush=AsyncFlushPolicy::Never,
      ),
    ),
  ).with_patch(fn(rec) {
    second_target.val = rec.target
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.error("default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.builder.default")
}

///|
async test "build async logger severity helpers use stored target without override" {
  let written_targets : Ref[Array[String]] = Ref([])

  let logger = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Trace,
        target="async.builder.helpers",
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=4,
        overflow=AsyncOverflowPolicy::Blocking,
        flush=AsyncFlushPolicy::Never,
      ),
    ),
  ).with_patch(fn(rec) {
    written_targets.val.push(rec.target)
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.debug("first")
    logger.info("second")
    logger.error("third")
    logger.shutdown()
  })

  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.builder.helpers")
  inspect(written_targets.val[1], content="async.builder.helpers")
  inspect(written_targets.val[2], content="async.builder.helpers")
}

///|
async test "async logger projection preserves async queue and failure state" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {  }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.projected.state",
    flush=fn(_) -> Unit raise {
      raise TestFlushError("projected facade flush exploded")
    },
  ).to_library_async_logger()
  let full = logger.to_async_logger()

  logger.info("one")
  logger.info("two")
  inspect(full.target, content="async.projected.state")
  inspect(full.pending_count(), content="2")
  inspect(full.dropped_count(), content="0")
  inspect(full.has_failed(), content="false")
  inspect(full.last_error(), content="")

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    full.wait_idle()
    inspect(full.has_failed(), content="true")
    inspect(full.last_error().contains("TestFlushError"), content="true")
    inspect(full.is_running(), content="false")
    inspect(
      full.pending_count(),
      content=if async_runtime_supports_background_worker() { "1" } else { "1" },
    )
    inspect(
      full.dropped_count(),
      content=if async_runtime_supports_background_worker() { "0" } else { "0" },
    )
    logger.shutdown()
  })

  inspect(full.is_closed(), content="true")
  inspect(full.has_failed(), content="true")
  inspect(full.last_error().contains("TestFlushError"), content="true")
}

///|
async test "async logger projection preserves file-backed runtime helpers through unwrap" {
  let configured = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.projected.file",
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::File,
          path="async-projected-file.log",
        ),
        queue=Some(
          @bitlogger.QueueConfig::new(
            2,
            overflow=@bitlogger.QueueOverflowPolicy::DropOldest,
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropOldest,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )
  let projected = configured.to_library_async_logger()
  let full = projected.to_async_logger()

  inspect(projected.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(projected.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.projected.file")

  full.error("one")
  full.error("two")
  full.error("three")
  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(
    full.sink.pending_count() == configured.sink.pending_count(),
    content="true",
  )
  inspect(
    full.sink.dropped_count() == configured.sink.dropped_count(),
    content="true",
  )
  inspect(
    full.sink.file_available() == configured.sink.file_available(),
    content="true",
  )
  inspect(
    full.sink.file_append_mode() == configured.sink.file_append_mode(),
    content="true",
  )
  inspect(
    full.sink.file_auto_flush() == configured.sink.file_auto_flush(),
    content="true",
  )

  let full_state = full.sink.file_state()
  let configured_state = configured.sink.file_state()
  inspect(full_state.path == configured_state.path, content="true")
  inspect(full_state.available == configured_state.available, content="true")
  inspect(full_state.append == configured_state.append, content="true")
  inspect(full_state.auto_flush == configured_state.auto_flush, content="true")
  inspect(
    full_state.open_failures == configured_state.open_failures,
    content="true",
  )
  inspect(
    full_state.write_failures == configured_state.write_failures,
    content="true",
  )
  inspect(
    full_state.flush_failures == configured_state.flush_failures,
    content="true",
  )
  inspect(
    full_state.rotation_failures == configured_state.rotation_failures,
    content="true",
  )

  match (full.sink.file_runtime_state(), configured.sink.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(full.sink.file_set_append_mode(false), content="true")
  inspect(configured.sink.file_append_mode(), content="false")
  inspect(
    full.sink.file_append_mode() == configured.sink.file_append_mode(),
    content="true",
  )

  inspect(full.sink.file_set_auto_flush(false), content="true")
  inspect(configured.sink.file_auto_flush(), content="false")
  inspect(
    full.sink.file_auto_flush() == configured.sink.file_auto_flush(),
    content="true",
  )

  inspect(
    full.sink.file_set_rotation(
      Some(@bitlogger.file_rotation(36, max_backups=2)),
    ),
    content="true",
  )
  inspect(configured.sink.file_rotation_enabled(), content="true")
  inspect(
    full.sink.file_rotation_enabled() == configured.sink.file_rotation_enabled(),
    content="true",
  )

  let reopen_append_ok = full.sink.file_reopen_append()
  inspect(
    reopen_append_ok == configured.sink.file_reopen_append(),
    content="true",
  )
  inspect(
    full.sink.file_append_mode() == configured.sink.file_append_mode(),
    content="true",
  )

  inspect(full.sink.file_clear_rotation(), content="true")
  inspect(configured.sink.file_rotation_enabled(), content="false")
  inspect(
    full.sink.file_rotation_enabled() == configured.sink.file_rotation_enabled(),
    content="true",
  )

  inspect(full.sink.file_reset_policy(), content="true")
  inspect(
    full.sink.file_policy_matches_default() ==
    configured.sink.file_policy_matches_default(),
    content="true",
  )

  inspect(full.sink.file_reset_failure_counters(), content="true")
  let reset_full_state = full.sink.file_state()
  let reset_configured_state = configured.sink.file_state()
  inspect(
    reset_full_state.open_failures == reset_configured_state.open_failures,
    content="true",
  )
  inspect(
    reset_full_state.write_failures == reset_configured_state.write_failures,
    content="true",
  )
  inspect(
    reset_full_state.flush_failures == reset_configured_state.flush_failures,
    content="true",
  )
  inspect(
    reset_full_state.rotation_failures ==
    reset_configured_state.rotation_failures,
    content="true",
  )

  inspect(
    full.sink.file_flush(),
    content=if configured.sink.file_available() { "true" } else { "false" },
  )
  inspect(full.pending_count() == configured.pending_count(), content="true")

  let close_expected = configured.sink.file_available()
  inspect(
    full.sink.file_close(),
    content=if close_expected { "true" } else { "false" },
  )
  inspect(
    full.sink.file_available() == configured.sink.file_available(),
    content="true",
  )
}

///|
test "application async logger aliases runtime async entry" {
  let logger = build_application_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        target="async.app",
        min_level=@bitlogger.Level::Warn,
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app")
}

///|
async test "application async logger builder matches direct async builder behavior" {
  let config = AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(
      min_level=@bitlogger.Level::Warn,
      target="async.app.same-build",
      timestamp=true,
      queue=Some(
        @bitlogger.QueueConfig::new(
          3,
          overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
        ),
      ),
      sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
    ),
    async_config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::DropOldest,
      flush=AsyncFlushPolicy::Shutdown,
    ),
  )
  let application = build_application_async_logger(config)
  let direct = build_async_logger(config)
  let application_state = application.state()
  let direct_state = direct.state()

  inspect(application.target, content=direct.target)
  inspect(application.timestamp == direct.timestamp, content="true")
  inspect(
    application.is_enabled(@bitlogger.Level::Error) ==
    direct.is_enabled(@bitlogger.Level::Error),
    content="true",
  )
  inspect(
    application.is_enabled(@bitlogger.Level::Info) ==
    direct.is_enabled(@bitlogger.Level::Info),
    content="true",
  )
  inspect(
    stringify_async_logger_state(application_state) ==
    stringify_async_logger_state(direct_state),
    content="true",
  )
  let application_sink_kind = match application.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  let direct_sink_kind = match direct.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  inspect(application_sink_kind == direct_sink_kind, content="true")

  application.info("skip")
  application.error("one")
  application.error("two")
  application.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(application.dropped_count() == direct.dropped_count(), content="true")
  inspect(application.is_closed() == direct.is_closed(), content="true")
  inspect(application.is_running() == direct.is_running(), content="true")
  inspect(
    application.sink.pending_count() == direct.sink.pending_count(),
    content="true",
  )
  inspect(
    application.sink.dropped_count() == direct.sink.dropped_count(),
    content="true",
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => application.run())
    group.spawn_bg(() => direct.run())
    application.shutdown()
    direct.shutdown()
  })

  inspect(application.is_closed() == direct.is_closed(), content="true")
  inspect(application.is_running() == direct.is_running(), content="true")
  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(application.dropped_count() == direct.dropped_count(), content="true")
  inspect(application.has_failed() == direct.has_failed(), content="true")
  inspect(application.last_error() == direct.last_error(), content="true")
}

///|
async test "application async builder preserves file-backed runtime helpers" {
  let config = AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(
      min_level=@bitlogger.Level::Warn,
      target="async.app.file.same-build",
      sink=@bitlogger.SinkConfig::new(
        kind=@bitlogger.SinkKind::File,
        path="async-app-file-same-build.log",
      ),
      queue=Some(
        @bitlogger.QueueConfig::new(
          3,
          overflow=@bitlogger.QueueOverflowPolicy::DropOldest,
        ),
      ),
    ),
    async_config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::DropOldest,
      flush=AsyncFlushPolicy::Shutdown,
    ),
  )
  let application = build_application_async_logger(config)
  let direct = build_async_logger(config)

  application.info("skip")
  application.error("one")
  application.error("two")
  application.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(application.dropped_count() == direct.dropped_count(), content="true")
  inspect(
    application.sink.pending_count() == direct.sink.pending_count(),
    content="true",
  )
  inspect(
    application.sink.dropped_count() == direct.sink.dropped_count(),
    content="true",
  )
  inspect(
    application.sink.file_available() == direct.sink.file_available(),
    content="true",
  )
  inspect(
    application.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    application.sink.file_auto_flush() == direct.sink.file_auto_flush(),
    content="true",
  )

  let application_state = application.sink.file_state()
  let direct_state = direct.sink.file_state()
  inspect(application_state.path == direct_state.path, content="true")
  inspect(application_state.available == direct_state.available, content="true")
  inspect(application_state.append == direct_state.append, content="true")
  inspect(
    application_state.auto_flush == direct_state.auto_flush,
    content="true",
  )
  inspect(
    application_state.open_failures == direct_state.open_failures,
    content="true",
  )
  inspect(
    application_state.write_failures == direct_state.write_failures,
    content="true",
  )
  inspect(
    application_state.flush_failures == direct_state.flush_failures,
    content="true",
  )
  inspect(
    application_state.rotation_failures == direct_state.rotation_failures,
    content="true",
  )

  match
    (application.sink.file_runtime_state(), direct.sink.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(
    application.sink.file_set_append_mode(false) ==
    direct.sink.file_set_append_mode(false),
    content="true",
  )
  inspect(
    application.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    application.sink.file_set_auto_flush(false) ==
    direct.sink.file_set_auto_flush(false),
    content="true",
  )
  inspect(
    application.sink.file_auto_flush() == direct.sink.file_auto_flush(),
    content="true",
  )
  inspect(
    application.sink.file_set_rotation(
      Some(@bitlogger.file_rotation(36, max_backups=2)),
    ) ==
    direct.sink.file_set_rotation(
      Some(@bitlogger.file_rotation(36, max_backups=2)),
    ),
    content="true",
  )
  inspect(
    application.sink.file_rotation_enabled() ==
    direct.sink.file_rotation_enabled(),
    content="true",
  )
  inspect(
    application.sink.file_reopen_append() == direct.sink.file_reopen_append(),
    content="true",
  )
  inspect(
    application.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    application.sink.file_clear_rotation() == direct.sink.file_clear_rotation(),
    content="true",
  )
  inspect(
    application.sink.file_reset_policy() == direct.sink.file_reset_policy(),
    content="true",
  )
  inspect(
    application.sink.file_policy_matches_default() ==
    direct.sink.file_policy_matches_default(),
    content="true",
  )
  inspect(
    application.sink.file_reset_failure_counters() ==
    direct.sink.file_reset_failure_counters(),
    content="true",
  )
  inspect(
    application.sink.file_flush() == direct.sink.file_flush(),
    content="true",
  )
  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(
    application.sink.file_close() == direct.sink.file_close(),
    content="true",
  )
}

///|
async test "application async logger keeps async helper surface" {
  let logger : ApplicationAsyncLogger = build_application_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.app.alias",
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropOldest,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )

  let state = logger.state()
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.is_closed(), content="false")
  inspect(logger.is_running(), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "application async logger shutdown clear abandons pending records" {
  let logger : ApplicationAsyncLogger = build_application_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Info,
        target="async.app.clear",
        sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
      ),
    ),
  )

  logger.info("one")
  inspect(logger.pending_count(), content="1")
  inspect(logger.dropped_count(), content="0")
  logger.shutdown(clear=true)
  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
async test "application async logger keeps broader async composition surface" {
  let logger : ApplicationAsyncLogger = build_application_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          min_level=@bitlogger.Level::Warn,
          target="async.app.compose",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=2,
          overflow=AsyncOverflowPolicy::DropNewest,
          flush=AsyncFlushPolicy::Shutdown,
        ),
      ),
    )
    .with_timestamp()
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .child("worker")

  inspect(logger.target, content="async.app.compose.worker")
  inspect(logger.timestamp, content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")

  logger.error("one")
  logger.error("two")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="0")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="0")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "application async logger log supports per-call target override" {
  let written_target : Ref[String] = Ref("")
  let written_message : Ref[String] = Ref("")
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger : ApplicationAsyncLogger = build_application_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          min_level=@bitlogger.Level::Warn,
          target="async.app.default",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
        ),
        async_config=AsyncLoggerConfig::new(max_pending=4),
      ),
    )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .with_patch(fn(rec) {
      written_target.val = rec.target
      written_message.val = rec.message
      written_fields.val = rec.fields
      rec
    })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      fields=[@bitlogger.field("mode", "test")],
      target="async.app.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.app.override")
  inspect(written_message.val, content="override")
  inspect(written_fields.val.length(), content="2")
  inspect(written_fields.val[0].key, content="service")
  inspect(written_fields.val[0].value, content="bitlogger")
  inspect(written_fields.val[1].key, content="mode")
  inspect(written_fields.val[1].value, content="test")

  let second_target : Ref[String] = Ref("")
  let second_message : Ref[String] = Ref("")
  let second_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let second : ApplicationAsyncLogger = build_application_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          min_level=@bitlogger.Level::Warn,
          target="async.app.default",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
        ),
        async_config=AsyncLoggerConfig::new(max_pending=4),
      ),
    )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .with_patch(fn(rec) {
      second_target.val = rec.target
      second_message.val = rec.message
      second_fields.val = rec.fields
      rec
    })

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.log(@bitlogger.Level::Error, "default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.app.default")
  inspect(second_message.val, content="default")
  inspect(second_fields.val.length(), content="1")
  inspect(second_fields.val[0].key, content="service")
}

///|
async test "application async logger severity helpers use stored target without override" {
  let written_levels : Ref[Array[String]] = Ref([])
  let written_targets : Ref[Array[String]] = Ref([])
  let written_fields : Ref[Array[Array[@bitlogger.Field]]] = Ref([])
  let logger : ApplicationAsyncLogger = build_application_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          min_level=@bitlogger.Level::Info,
          target="async.app.helpers",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::Console),
        ),
        async_config=AsyncLoggerConfig::new(max_pending=4),
      ),
    )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .with_patch(fn(rec) {
      written_levels.val.push(rec.level.label())
      written_targets.val.push(rec.target)
      written_fields.val.push(rec.fields)
      rec
    })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("info", fields=[@bitlogger.field("mode", "info")])
    logger.warn("warn", fields=[@bitlogger.field("mode", "warn")])
    logger.error("error", fields=[@bitlogger.field("mode", "error")])
    logger.shutdown()
  })

  inspect(written_levels.val.length(), content="3")
  inspect(written_levels.val[0], content="INFO")
  inspect(written_levels.val[1], content="WARN")
  inspect(written_levels.val[2], content="ERROR")
  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.app.helpers")
  inspect(written_targets.val[1], content="async.app.helpers")
  inspect(written_targets.val[2], content="async.app.helpers")
  inspect(written_fields.val[0].length(), content="2")
  inspect(written_fields.val[1].length(), content="2")
  inspect(written_fields.val[2].length(), content="2")
  inspect(written_fields.val[0][0].key, content="service")
  inspect(written_fields.val[0][1].value, content="info")
  inspect(written_fields.val[1][0].key, content="service")
  inspect(written_fields.val[1][1].value, content="warn")
  inspect(written_fields.val[2][0].key, content="service")
  inspect(written_fields.val[2][1].value, content="error")
}

///|
test "application async logger builder preserves sync queue-backed runtime sink" {
  let logger = build_application_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.app.queued",
        queue=Some(
          @bitlogger.QueueConfig::new(
            3,
            overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.queued")
  inspect(logger.sink.pending_count(), content="0")
  inspect(logger.sink.dropped_count(), content="0")
  inspect(
    match logger.sink {
      @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
      @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
      @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
      @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
      _ => "Other"
    },
    content="QueuedConsole",
  )
}

///|
test "application text async logger uses text facade build path" {
  let logger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.app.text",
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.text")
}

///|
async test "application text builder matches direct text builder behavior" {
  let config = AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(
      min_level=@bitlogger.Level::Warn,
      target="async.app.text.same-build",
      timestamp=true,
      queue=Some(
        @bitlogger.QueueConfig::new(
          3,
          overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
        ),
      ),
      sink=@bitlogger.SinkConfig::new(
        kind=@bitlogger.SinkKind::TextConsole,
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
          template="TEXT:{target}:{message}",
        ),
      ),
    ),
    async_config=AsyncLoggerConfig::new(
      max_pending=2,
      overflow=AsyncOverflowPolicy::DropOldest,
      flush=AsyncFlushPolicy::Shutdown,
    ),
  )
  let logger = build_application_text_async_logger(config)
  let direct = build_async_text_logger(config)
  let logger_state = logger.state()
  let direct_state = direct.state()

  inspect(logger.target, content=direct.target)
  inspect(logger.timestamp == direct.timestamp, content="true")
  inspect(
    logger.is_enabled(@bitlogger.Level::Error) ==
    direct.is_enabled(@bitlogger.Level::Error),
    content="true",
  )
  inspect(
    logger.is_enabled(@bitlogger.Level::Info) ==
    direct.is_enabled(@bitlogger.Level::Info),
    content="true",
  )
  inspect(
    stringify_async_logger_state(logger_state) ==
    stringify_async_logger_state(direct_state),
    content="true",
  )
  let record = @bitlogger.Record::new(
    @bitlogger.Level::Error,
    "boom",
    target="async.app.text.same-build",
  )
  inspect(
    (logger.sink.formatter)(record) == (direct.sink.formatter)(record),
    content="true",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(logger.pending_count() == direct.pending_count(), content="true")
  inspect(logger.dropped_count() == direct.dropped_count(), content="true")
  inspect(logger.is_closed() == direct.is_closed(), content="true")
  inspect(logger.is_running() == direct.is_running(), content="true")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    group.spawn_bg(() => direct.run())
    logger.shutdown()
    direct.shutdown()
  })

  inspect(logger.is_closed() == direct.is_closed(), content="true")
  inspect(logger.is_running() == direct.is_running(), content="true")
  inspect(logger.pending_count() == direct.pending_count(), content="true")
  inspect(logger.dropped_count() == direct.dropped_count(), content="true")
  inspect(logger.has_failed() == direct.has_failed(), content="true")
  inspect(logger.last_error() == direct.last_error(), content="true")
}

///|
async test "application text async logger keeps async helper surface" {
  let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.app.text.alias",
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropOldest,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )

  let state = logger.state()
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.is_closed(), content="false")
  inspect(logger.is_running(), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "application text async logger shutdown clear abandons pending records" {
  let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Info,
        target="async.app.text.clear",
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
      ),
    ),
  )

  logger.info("one")
  inspect(logger.pending_count(), content="1")
  inspect(logger.dropped_count(), content="0")
  logger.shutdown(clear=true)
  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
async test "application text async logger keeps broader async composition surface" {
  let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.text_console(
          min_level=@bitlogger.Level::Warn,
          target="async.app.text.compose",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=2,
          overflow=AsyncOverflowPolicy::DropNewest,
          flush=AsyncFlushPolicy::Shutdown,
        ),
      ),
    )
    .with_timestamp()
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .child("worker")

  inspect(logger.target, content="async.app.text.compose.worker")
  inspect(logger.timestamp, content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")

  logger.error("one")
  logger.error("two")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="0")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="0")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "application text async logger log supports per-call target override" {
  let written_target : Ref[String] = Ref("")
  let written_message : Ref[String] = Ref("")
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.text_console(
          min_level=@bitlogger.Level::Warn,
          target="async.app.text.default",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
        async_config=AsyncLoggerConfig::new(max_pending=4),
      ),
    )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .with_patch(fn(rec) {
      written_target.val = rec.target
      written_message.val = rec.message
      written_fields.val = rec.fields
      rec
    })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      fields=[@bitlogger.field("mode", "test")],
      target="async.app.text.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.app.text.override")
  inspect(written_message.val, content="override")
  inspect(written_fields.val.length(), content="2")
  inspect(written_fields.val[0].key, content="service")
  inspect(written_fields.val[0].value, content="bitlogger")
  inspect(written_fields.val[1].key, content="mode")
  inspect(written_fields.val[1].value, content="test")

  let second_target : Ref[String] = Ref("")
  let second_message : Ref[String] = Ref("")
  let second_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let second : ApplicationTextAsyncLogger = build_application_text_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.text_console(
          min_level=@bitlogger.Level::Warn,
          target="async.app.text.default",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
        async_config=AsyncLoggerConfig::new(max_pending=4),
      ),
    )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .with_patch(fn(rec) {
      second_target.val = rec.target
      second_message.val = rec.message
      second_fields.val = rec.fields
      rec
    })

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.log(@bitlogger.Level::Error, "default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.app.text.default")
  inspect(second_message.val, content="default")
  inspect(second_fields.val.length(), content="1")
  inspect(second_fields.val[0].key, content="service")
}

///|
async test "application text async logger severity helpers use stored target without override" {
  let written_levels : Ref[Array[String]] = Ref([])
  let written_targets : Ref[Array[String]] = Ref([])
  let written_fields : Ref[Array[Array[@bitlogger.Field]]] = Ref([])
  let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.text_console(
          min_level=@bitlogger.Level::Info,
          target="async.app.text.helpers",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
        async_config=AsyncLoggerConfig::new(max_pending=4),
      ),
    )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .with_patch(fn(rec) {
      written_levels.val.push(rec.level.label())
      written_targets.val.push(rec.target)
      written_fields.val.push(rec.fields)
      rec
    })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("info", fields=[@bitlogger.field("mode", "info")])
    logger.warn("warn", fields=[@bitlogger.field("mode", "warn")])
    logger.error("error", fields=[@bitlogger.field("mode", "error")])
    logger.shutdown()
  })

  inspect(written_levels.val.length(), content="3")
  inspect(written_levels.val[0], content="INFO")
  inspect(written_levels.val[1], content="WARN")
  inspect(written_levels.val[2], content="ERROR")
  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.app.text.helpers")
  inspect(written_targets.val[1], content="async.app.text.helpers")
  inspect(written_targets.val[2], content="async.app.text.helpers")
  inspect(written_fields.val[0].length(), content="2")
  inspect(written_fields.val[1].length(), content="2")
  inspect(written_fields.val[2].length(), content="2")
  inspect(written_fields.val[0][0].key, content="service")
  inspect(written_fields.val[0][1].value, content="info")
  inspect(written_fields.val[1][0].key, content="service")
  inspect(written_fields.val[1][1].value, content="warn")
  inspect(written_fields.val[2][0].key, content="service")
  inspect(written_fields.val[2][1].value, content="error")
}

///|
test "application text async logger builder ignores sync queue layer" {
  let logger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.app.text.queued",
        queue=Some(
          @bitlogger.QueueConfig::new(
            3,
            overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
          ),
        ),
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.text.queued")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="0")
}

///|
test "application text async logger ignores sink kind and still uses text formatter" {
  let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.app.text.kind.alias",
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::File,
          path="ignored.log",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
            template="TEXT:{target}:{message}",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.text.kind.alias")
  let rendered = (logger.sink.formatter)(
    @bitlogger.Record::new(
      @bitlogger.Level::Error,
      "boom",
      target="async.app.text.kind.alias",
    ),
  )
  inspect(rendered, content="TEXT:async.app.text.kind.alias:boom")
}

///|
test "build async text logger keeps text-console config fields" {
  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.direct",
        timestamp=true,
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=3,
        overflow=AsyncOverflowPolicy::DropOldest,
      ),
    ),
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.text.direct")
  inspect(logger.timestamp, content="true")
  inspect(
    match logger.flush_policy() {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Never",
  )
  let rendered = (logger.sink.formatter)(
    @bitlogger.Record::new(
      @bitlogger.Level::Error,
      "boom",
      target="async.text.direct",
    ),
  )
  inspect(rendered, content="[ERROR] | [async.text.direct] | boom")
}

///|
test "build async text logger ignores sink kind and still uses text formatter" {
  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.kind",
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::File,
          path="ignored.log",
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
            template="TEXT:{target}:{message}",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.text.kind")
  let rendered = (logger.sink.formatter)(
    @bitlogger.Record::new(
      @bitlogger.Level::Error,
      "boom",
      target="async.text.kind",
    ),
  )
  inspect(rendered, content="TEXT:async.text.kind:boom")
}

///|
async test "build async text logger keeps direct helper surface" {
  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.helpers",
        timestamp=true,
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::DropOldest,
        flush=AsyncFlushPolicy::Shutdown,
      ),
    ),
  )

  let state = logger.state()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.text.helpers")
  inspect(logger.timestamp, content="true")
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.is_closed(), content="false")
  inspect(logger.is_running(), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "build async text logger log supports per-call target override" {
  let written_target : Ref[String] = Ref("")

  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.builder.default",
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
        flush=AsyncFlushPolicy::Never,
      ),
    ),
  ).with_patch(fn(rec) {
    written_target.val = rec.target
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      target="async.text.builder.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.text.builder.override")

  let second_target : Ref[String] = Ref("")

  let second = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.builder.default",
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=2,
        overflow=AsyncOverflowPolicy::Blocking,
        flush=AsyncFlushPolicy::Never,
      ),
    ),
  ).with_patch(fn(rec) {
    second_target.val = rec.target
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.error("default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.text.builder.default")
}

///|
async test "build async text logger severity helpers use stored target without override" {
  let written_targets : Ref[Array[String]] = Ref([])

  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Info,
        target="async.text.builder.helpers",
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(
        max_pending=4,
        overflow=AsyncOverflowPolicy::Blocking,
        flush=AsyncFlushPolicy::Never,
      ),
    ),
  ).with_patch(fn(rec) {
    written_targets.val.push(rec.target)
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.info("first")
    logger.warn("second")
    logger.error("third")
    logger.shutdown()
  })

  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.text.builder.helpers")
  inspect(written_targets.val[1], content="async.text.builder.helpers")
  inspect(written_targets.val[2], content="async.text.builder.helpers")
}

///|
async test "build async text logger batch flush policy keeps default no-op flush callback" {
  let config = AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(
      min_level=@bitlogger.Level::Info,
      target="async.text.batch.flush",
      timestamp=true,
      sink=@bitlogger.SinkConfig::new(
        kind=@bitlogger.SinkKind::TextConsole,
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
          template="TEXT:{target}:{message}",
        ),
      ),
    ),
    async_config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      max_batch=2,
      flush=AsyncFlushPolicy::Batch,
    ),
  )
  let configured = build_async_text_logger(config)
  let manual = async_logger(
    @bitlogger.text_console_sink(
      config.logger.sink.text_formatter.to_formatter(),
    ),
    config=config.async_config,
    min_level=config.logger.min_level,
    target=config.logger.target,
    flush=fn(_) -> Unit raise {
      raise TestFlushError("text batch flush exploded")
    },
  ).with_timestamp(enabled=config.logger.timestamp)

  @async.with_task_group(group => {
    group.spawn_bg(() => configured.run())
    group.spawn_bg(allow_failure=true, () => manual.run())

    configured.error("one")
    configured.error("two")
    manual.error("one")
    manual.error("two")

    configured.wait_idle()
    manual.wait_idle()

    inspect(
      match configured.flush_policy() {
        AsyncFlushPolicy::Never => "Never"
        AsyncFlushPolicy::Batch => "Batch"
        AsyncFlushPolicy::Shutdown => "Shutdown"
      },
      content="Batch",
    )
    inspect(
      match manual.flush_policy() {
        AsyncFlushPolicy::Never => "Never"
        AsyncFlushPolicy::Batch => "Batch"
        AsyncFlushPolicy::Shutdown => "Shutdown"
      },
      content="Batch",
    )
    inspect(configured.has_failed(), content="false")
    inspect(configured.last_error(), content="")
    inspect(configured.pending_count(), content="0")
    inspect(manual.has_failed(), content="true")
    inspect(manual.last_error().contains("TestFlushError"), content="true")

    configured.shutdown()
    manual.shutdown(clear=true)
  })

  inspect(configured.is_closed(), content="true")
  inspect(configured.is_running(), content="false")
  inspect(configured.has_failed(), content="false")
  inspect(configured.last_error(), content="")
  inspect(configured.pending_count(), content="0")
  inspect(manual.is_closed(), content="true")
  inspect(manual.is_running(), content="false")
  inspect(manual.has_failed(), content="true")
  inspect(manual.last_error().contains("TestFlushError"), content="true")
}

///|
async test "build async text logger shutdown flush policy keeps default no-op flush callback" {
  let config = AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(
      min_level=@bitlogger.Level::Info,
      target="async.text.shutdown.flush",
      timestamp=true,
      sink=@bitlogger.SinkConfig::new(
        kind=@bitlogger.SinkKind::TextConsole,
        text_formatter=@bitlogger.TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
          template="TEXT:{target}:{message}",
        ),
      ),
    ),
    async_config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      max_batch=2,
      flush=AsyncFlushPolicy::Shutdown,
    ),
  )
  let configured = build_async_text_logger(config)
  let manual = async_logger(
    @bitlogger.text_console_sink(
      config.logger.sink.text_formatter.to_formatter(),
    ),
    config=config.async_config,
    min_level=config.logger.min_level,
    target=config.logger.target,
    flush=fn(_) -> Unit raise {
      raise TestFlushError("text shutdown flush exploded")
    },
  ).with_timestamp(enabled=config.logger.timestamp)

  @async.with_task_group(group => {
    group.spawn_bg(() => configured.run())
    group.spawn_bg(allow_failure=true, () => manual.run())

    configured.error("one")
    configured.error("two")
    manual.error("one")
    manual.error("two")

    configured.shutdown()
    manual.shutdown()
  })

  inspect(
    match configured.flush_policy() {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )
  inspect(
    match manual.flush_policy() {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )
  inspect(configured.is_closed(), content="true")
  inspect(configured.is_running(), content="false")
  inspect(configured.has_failed(), content="false")
  inspect(configured.last_error(), content="")
  inspect(configured.pending_count(), content="0")
  inspect(manual.is_closed(), content="true")
  inspect(manual.is_running(), content="false")
  inspect(manual.has_failed(), content="true")
  inspect(manual.last_error().contains("TestFlushError"), content="true")
  inspect(manual.pending_count(), content="0")
}

///|
test "build async text logger ignores sync queue layer" {
  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.queued",
        queue=Some(
          @bitlogger.QueueConfig::new(
            3,
            overflow=@bitlogger.QueueOverflowPolicy::DropNewest,
          ),
        ),
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(
            show_timestamp=false,
            separator=" | ",
          ),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.text.queued")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="0")
}

///|
test "application async logger can be built from config text" {
  let logger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.json")
}

///|
async test "application async parse-build matches parsed direct async builder behavior" {
  let raw = "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.same-build\",\"timestamp\":true,\"queue\":{\"max_pending\":3,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropOldest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Shutdown\"}}"
  let application = parse_and_build_application_async_logger(raw)
  let direct = build_async_logger(parse_async_logger_build_config_text(raw))
  let application_state = application.state()
  let direct_state = direct.state()

  inspect(application.target, content=direct.target)
  inspect(application.timestamp == direct.timestamp, content="true")
  inspect(
    application.is_enabled(@bitlogger.Level::Error) ==
    direct.is_enabled(@bitlogger.Level::Error),
    content="true",
  )
  inspect(
    application.is_enabled(@bitlogger.Level::Info) ==
    direct.is_enabled(@bitlogger.Level::Info),
    content="true",
  )
  inspect(
    stringify_async_logger_state(application_state) ==
    stringify_async_logger_state(direct_state),
    content="true",
  )
  let application_sink_kind = match application.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  let direct_sink_kind = match direct.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
  }
  inspect(application_sink_kind == direct_sink_kind, content="true")

  application.info("skip")
  application.error("one")
  application.error("two")
  application.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(application.dropped_count() == direct.dropped_count(), content="true")
  inspect(application.is_closed() == direct.is_closed(), content="true")
  inspect(application.is_running() == direct.is_running(), content="true")
  inspect(
    application.sink.pending_count() == direct.sink.pending_count(),
    content="true",
  )
  inspect(
    application.sink.dropped_count() == direct.sink.dropped_count(),
    content="true",
  )

  @async.with_task_group(group => {
    group.spawn_bg(() => application.run())
    group.spawn_bg(() => direct.run())
    application.shutdown()
    direct.shutdown()
  })

  inspect(application.is_closed() == direct.is_closed(), content="true")
  inspect(application.is_running() == direct.is_running(), content="true")
  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(application.dropped_count() == direct.dropped_count(), content="true")
  inspect(application.has_failed() == direct.has_failed(), content="true")
  inspect(application.last_error() == direct.last_error(), content="true")
}

///|
async test "application async parse-build preserves file-backed runtime helpers" {
  let raw = "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.file.same-build\",\"queue\":{\"max_pending\":3,\"overflow\":\"DropOldest\"},\"sink\":{\"kind\":\"file\",\"path\":\"async-app-json-file-same-build.log\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropOldest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Shutdown\"}}"
  let application = parse_and_build_application_async_logger(raw)
  let direct = build_async_logger(parse_async_logger_build_config_text(raw))

  application.info("skip")
  application.error("one")
  application.error("two")
  application.error("three")
  direct.info("skip")
  direct.error("one")
  direct.error("two")
  direct.error("three")

  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(application.dropped_count() == direct.dropped_count(), content="true")
  inspect(
    application.sink.pending_count() == direct.sink.pending_count(),
    content="true",
  )
  inspect(
    application.sink.dropped_count() == direct.sink.dropped_count(),
    content="true",
  )
  inspect(
    application.sink.file_available() == direct.sink.file_available(),
    content="true",
  )
  inspect(
    application.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    application.sink.file_auto_flush() == direct.sink.file_auto_flush(),
    content="true",
  )

  let application_state = application.sink.file_state()
  let direct_state = direct.sink.file_state()
  inspect(application_state.path == direct_state.path, content="true")
  inspect(application_state.available == direct_state.available, content="true")
  inspect(application_state.append == direct_state.append, content="true")
  inspect(
    application_state.auto_flush == direct_state.auto_flush,
    content="true",
  )
  inspect(
    application_state.open_failures == direct_state.open_failures,
    content="true",
  )
  inspect(
    application_state.write_failures == direct_state.write_failures,
    content="true",
  )
  inspect(
    application_state.flush_failures == direct_state.flush_failures,
    content="true",
  )
  inspect(
    application_state.rotation_failures == direct_state.rotation_failures,
    content="true",
  )

  match
    (application.sink.file_runtime_state(), direct.sink.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(
    application.sink.file_set_append_mode(false) ==
    direct.sink.file_set_append_mode(false),
    content="true",
  )
  inspect(
    application.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    application.sink.file_set_auto_flush(false) ==
    direct.sink.file_set_auto_flush(false),
    content="true",
  )
  inspect(
    application.sink.file_auto_flush() == direct.sink.file_auto_flush(),
    content="true",
  )
  inspect(
    application.sink.file_set_rotation(
      Some(@bitlogger.file_rotation(36, max_backups=2)),
    ) ==
    direct.sink.file_set_rotation(
      Some(@bitlogger.file_rotation(36, max_backups=2)),
    ),
    content="true",
  )
  inspect(
    application.sink.file_rotation_enabled() ==
    direct.sink.file_rotation_enabled(),
    content="true",
  )
  inspect(
    application.sink.file_reopen_append() == direct.sink.file_reopen_append(),
    content="true",
  )
  inspect(
    application.sink.file_append_mode() == direct.sink.file_append_mode(),
    content="true",
  )
  inspect(
    application.sink.file_clear_rotation() == direct.sink.file_clear_rotation(),
    content="true",
  )
  inspect(
    application.sink.file_reset_policy() == direct.sink.file_reset_policy(),
    content="true",
  )
  inspect(
    application.sink.file_policy_matches_default() ==
    direct.sink.file_policy_matches_default(),
    content="true",
  )
  inspect(
    application.sink.file_reset_failure_counters() ==
    direct.sink.file_reset_failure_counters(),
    content="true",
  )
  inspect(
    application.sink.file_flush() == direct.sink.file_flush(),
    content="true",
  )
  inspect(application.pending_count() == direct.pending_count(), content="true")
  inspect(
    application.sink.file_close() == direct.sink.file_close(),
    content="true",
  )
}

///|
async test "parsed application async logger keeps async helper surface" {
  let logger : ApplicationAsyncLogger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.helpers\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropOldest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Shutdown\"}}",
  )

  let state = logger.state()
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(
    match state.flush_policy {
      AsyncFlushPolicy::Never => "Never"
      AsyncFlushPolicy::Batch => "Batch"
      AsyncFlushPolicy::Shutdown => "Shutdown"
    },
    content="Shutdown",
  )

  logger.info("skip")
  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.is_closed(), content="false")
  inspect(logger.is_running(), content="false")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "parsed application async logger shutdown clear abandons pending records" {
  let logger : ApplicationAsyncLogger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"info\",\"target\":\"async.app.json.clear\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )

  logger.info("one")
  inspect(logger.pending_count(), content="1")
  inspect(logger.dropped_count(), content="0")
  logger.shutdown(clear=true)
  inspect(logger.is_closed(), content="true")
  inspect(logger.is_running(), content="false")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="1")
}

///|
async test "parsed application async logger keeps broader async composition surface" {
  let logger : ApplicationAsyncLogger = parse_and_build_application_async_logger(
      "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.compose\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Shutdown\"}}",
    )
    .with_timestamp()
    .with_context_fields([@bitlogger.field("service", "bitlogger")])
    .child("worker")

  inspect(logger.target, content="async.app.json.compose.worker")
  inspect(logger.timestamp, content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")

  logger.error("one")
  logger.error("two")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="0")

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.shutdown()
  })

  inspect(logger.is_closed(), content="true")
  inspect(logger.pending_count(), content="0")
  inspect(logger.dropped_count(), content="0")
  inspect(logger.has_failed(), content="false")
  inspect(logger.last_error(), content="")
}

///|
async test "parsed application async logger log supports per-call target override" {
  let written_target : Ref[String] = Ref("")

  let logger : ApplicationAsyncLogger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.default\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  ).with_patch(fn(rec) {
    written_target.val = rec.target
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.log(
      @bitlogger.Level::Error,
      "override",
      target="async.app.json.override",
    )
    logger.shutdown()
  })

  inspect(written_target.val, content="async.app.json.override")

  let second_target : Ref[String] = Ref("")

  let second : ApplicationAsyncLogger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.default\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  ).with_patch(fn(rec) {
    second_target.val = rec.target
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => second.run())
    second.error("default")
    second.shutdown()
  })

  inspect(second_target.val, content="async.app.json.default")
}

///|
async test "parsed application async logger severity helpers use stored target without override" {
  let written_targets : Ref[Array[String]] = Ref([])

  let logger : ApplicationAsyncLogger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"trace\",\"target\":\"async.app.json.helpers.target\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":4,\"overflow\":\"Blocking\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  ).with_patch(fn(rec) {
    written_targets.val.push(rec.target)
    rec
  })

  @async.with_task_group(group => {
    group.spawn_bg(() => logger.run())
    logger.debug("first")
    logger.info("second")
    logger.error("third")
    logger.shutdown()
  })

  inspect(written_targets.val.length(), content="3")
  inspect(written_targets.val[0], content="async.app.json.helpers.target")
  inspect(written_targets.val[1], content="async.app.json.helpers.target")
  inspect(written_targets.val[2], content="async.app.json.helpers.target")
}

///|
test "application async logger parse-and-build preserves parsed sync queue layer" {
  let logger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.queued\",\"queue\":{\"max_pending\":3,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.json.queued")
  inspect(
    match logger.sink {
      @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
      @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
      @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
      @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
      _ => "Other"
    },
    content="QueuedConsole",
  )
}

///|
test "async parse-build facades forward parse failures" {
  let raw = "{\"logger\":{\"sink\":{\"kind\":\"file\",\"path\":\"\"}},\"async_config\":{\"max_pending\":2}}"

  let application_error = (fn() -> String raise {
    ignore(parse_and_build_application_async_logger(raw))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(application_error != "no error", content="true")

  let library_error = (fn() -> String raise {
    ignore(parse_and_build_library_async_logger(raw))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(library_error != "no error", content="true")
}
