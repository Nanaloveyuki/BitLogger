suberror TestFlushError {
  TestFlushError(String)
}

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

async test "closed blocking logger does not add pending count on later log attempts" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {

    }),
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
  inspect(wrong_type_error.contains("Expected number at async_config.max_pending"), content="true")

  let invalid_enum_error = (fn() -> String raise {
    ignore(parse_async_logger_config_text("{\"overflow\":\"Burst\"}"))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(invalid_enum_error.contains("Unsupported async overflow policy: Burst"), content="true")

  let invalid_build_root_error = (fn() -> String raise {
    ignore(parse_async_logger_build_config_text("[]"))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(invalid_build_root_error.contains("Expected object at async logger build config root"), content="true")

  let nested_sync_error = (fn() -> String raise {
    ignore(parse_async_logger_build_config_text("{\"logger\":{\"timestamp\":\"true\"}}"))
    "no error"
  })() catch {
    err => err.to_string()
  }
  inspect(nested_sync_error.contains("ConfigError.InvalidConfig"), content="true")
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

test "async runtime mode and worker flag encode target contract" {
  let mode_label = async_runtime_mode_label(async_runtime_mode())
  let worker = async_runtime_supports_background_worker()
  inspect(mode_label == "native_worker" || mode_label == "compatibility", content="true")
  inspect((mode_label == "native_worker") == worker, content="true")
  inspect((mode_label == "compatibility") == !worker, content="true")
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

async test "async logger records worker failures and wait_idle stops early" {
  let writes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {
      writes.val += 1
    }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.failure",
    flush=fn(_) -> Int raise {
      raise TestFlushError("flush exploded")
    },
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
}

async test "later started run resets async failure state before draining remaining backlog" {
  let writes : Ref[Int] = Ref(0)
  let flushes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {
      writes.val += 1
    }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.retry",
    flush=fn(_) -> Int raise {
      flushes.val += 1
      if flushes.val == 1 {
        raise TestFlushError("flush exploded once")
      }
      1
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

    group.spawn_bg(() => logger.run())
    while !logger.is_running() {
      @async.pause()
    }
    inspect(logger.has_failed(), content="false")
    inspect(logger.last_error(), content="")
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

async test "shutdown after worker failure uses runtime-specific pending cleanup" {
  let writes : Ref[Int] = Ref(0)
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {
      writes.val += 1
    }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.failure.shutdown",
    flush=fn(_) -> Int raise {
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
  inspect(
    logger.pending_count(),
    content=if async_runtime_supports_background_worker() { "0" } else { "1" },
  )
  inspect(
    logger.dropped_count(),
    content=if async_runtime_supports_background_worker() { "1" } else { "0" },
  )
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

async test "library async shutdown preserves wrapped failure cleanup semantics" {
  let writes : Ref[Int] = Ref(0)
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) {
      writes.val += 1
    }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.lib.failure",
    flush=fn(_) -> Int raise {
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
  inspect(
    full.pending_count(),
    content=if async_runtime_supports_background_worker() { "0" } else { "1" },
  )
  inspect(
    full.dropped_count(),
    content=if async_runtime_supports_background_worker() { "1" } else { "0" },
  )
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

test "library async logger parse-and-build preserves parsed sync queue layer" {
  let logger = parse_and_build_library_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.lib.config.queued\",\"queue\":{\"max_pending\":3,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.config.queued")
  inspect(match full.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")
}

test "library async text logger can be built from typed config" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.lib.text",
        text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  let full = logger.to_async_logger()
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.text")
}

test "library async text logger builder ignores sync queue layer" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.lib.text.queued",
        queue=Some(@bitlogger.QueueConfig::new(3, overflow=@bitlogger.QueueOverflowPolicy::DropNewest)),
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
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

async test "async logger projection preserves async queue and failure state" {
  let logger = async_logger(
    @bitlogger.callback_sink(fn(_) {

    }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.projected.state",
    flush=fn(_) -> Int raise {
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

test "application async logger builder preserves sync queue-backed runtime sink" {
  let logger = build_application_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.app.queued",
        queue=Some(@bitlogger.QueueConfig::new(3, overflow=@bitlogger.QueueOverflowPolicy::DropNewest)),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.queued")
  inspect(logger.sink.pending_count(), content="0")
  inspect(logger.sink.dropped_count(), content="0")
  inspect(match logger.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")
}

test "application text async logger uses text facade build path" {
  let logger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.app.text",
        text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=2),
    ),
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.text")
}

test "application text async logger builder ignores sync queue layer" {
  let logger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.app.text.queued",
        queue=Some(@bitlogger.QueueConfig::new(3, overflow=@bitlogger.QueueOverflowPolicy::DropNewest)),
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
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

test "build async text logger keeps text-console config fields" {
  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.direct",
        timestamp=true,
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
        ),
      ),
      async_config=AsyncLoggerConfig::new(max_pending=3, overflow=AsyncOverflowPolicy::DropOldest),
    ),
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.text.direct")
  inspect(logger.timestamp, content="true")
  inspect(match logger.flush_policy() {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Never")
}

test "build async text logger ignores sync queue layer" {
  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.queued",
        queue=Some(@bitlogger.QueueConfig::new(3, overflow=@bitlogger.QueueOverflowPolicy::DropNewest)),
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
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

test "application async logger can be built from config text" {
  let logger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )
  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.json")
}

test "application async logger parse-and-build preserves parsed sync queue layer" {
  let logger = parse_and_build_application_async_logger(
    "{\"logger\":{\"min_level\":\"warn\",\"target\":\"async.app.json.queued\",\"queue\":{\"max_pending\":3,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
  )

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(logger.target, content="async.app.json.queued")
  inspect(match logger.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")
}
