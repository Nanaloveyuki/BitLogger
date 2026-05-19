async test "shutdown drains pending records" {
  inspect(async_runtime_mode_label(async_runtime_mode()) == "native_worker" || async_runtime_mode_label(async_runtime_mode()) == "compatibility", content="true")
  let written : Ref[Array[String]] = Ref([])
  let flushes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      written.val.push(rec.message)
    }),
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
      1
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
  inspect(match logger.flush_policy() {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Batch")
  inspect(written.val.length(), content="2")
  inspect(written.val[0], content="one")
  inspect(written.val[1], content="two")
  inspect(flushes.val, content="1")
}

async test "close clear counts abandoned records as dropped" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {

    }),
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

async test "shutdown clear closes without worker startup" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {

    }),
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
  inspect(match config.overflow {
    AsyncOverflowPolicy::Blocking => "Blocking"
    AsyncOverflowPolicy::DropOldest => "DropOldest"
    AsyncOverflowPolicy::DropNewest => "DropNewest"
  }, content="DropOldest")
  inspect(match config.flush {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Batch")
}

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
  inspect(match config.async_config.overflow {
    AsyncOverflowPolicy::Blocking => "Blocking"
    AsyncOverflowPolicy::DropOldest => "DropOldest"
    AsyncOverflowPolicy::DropNewest => "DropNewest"
  }, content="DropNewest")
  inspect(match config.async_config.flush {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")
}

test "async runtime capability helpers stay consistent" {
  let mode = async_runtime_mode()
  let state = async_runtime_state()
  let worker_supported = match mode {
    AsyncRuntimeMode::NativeWorker => true
    AsyncRuntimeMode::Compatibility => false
  }
  inspect(
    async_runtime_mode_label(mode) == "native_worker" || async_runtime_mode_label(mode) == "compatibility",
    content="true",
  )
  inspect(async_runtime_supports_background_worker() == worker_supported, content="true")
  inspect(async_runtime_mode_label(state.mode) == async_runtime_mode_label(mode), content="true")
  inspect(state.background_worker == worker_supported, content="true")
  inspect(
    stringify_async_runtime_state(state),
    content=if worker_supported {
      "{\"mode\":\"native_worker\",\"background_worker\":true}"
    } else {
      "{\"mode\":\"compatibility\",\"background_worker\":false}"
    },
  )
}

test "async logger state snapshot reflects current counters and runtime" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {

    }),
    config=AsyncLoggerConfig::new(
      max_pending=3,
      overflow=AsyncOverflowPolicy::DropNewest,
      flush=AsyncFlushPolicy::Shutdown,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.state",
  )
  let state = logger.state()
  inspect(async_runtime_mode_label(state.runtime.mode) == async_runtime_mode_label(async_runtime_mode()), content="true")
  inspect(state.runtime.background_worker == async_runtime_supports_background_worker(), content="true")
  inspect(state.pending_count, content="0")
  inspect(state.dropped_count, content="0")
  inspect(state.is_closed, content="false")
  inspect(state.is_running, content="false")
  inspect(state.has_failed, content="false")
  inspect(state.last_error, content="")
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")
  inspect(
    stringify_async_logger_state(state),
    content=if async_runtime_supports_background_worker() {
      "{\"runtime\":{\"mode\":\"native_worker\",\"background_worker\":true},\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    } else {
      "{\"runtime\":{\"mode\":\"compatibility\",\"background_worker\":false},\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    },
  )
}

async test "run drains queued records in compatibility backends too" {
  let written : Ref[Array[String]] = Ref([])
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      written.val.push(rec.message)
    }),
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
  ).with_context_fields([@bitlogger.field("service", "bitlogger")]).child("worker")

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

async test "library async logger can be built from config" {
  let logger = parse_and_build_library_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.config\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  let full = logger.to_async_logger()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.config")
}

async test "async logger can project to library async logger" {
  let logger = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(target="async.projected", min_level=@bitlogger.Level::Warn),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  ).to_library_async_logger()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.to_async_logger().target, content="async.projected")
}

test "application async logger aliases runtime async entry" {
  let logger = build_application_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(target="async.app", min_level=@bitlogger.Level::Warn),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app")
}

test "application async logger can be built from config text" {
  let logger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.json")
}
