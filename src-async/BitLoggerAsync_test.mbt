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
  inspect(config_obj.get("max_pending").unwrap().as_number().unwrap().to_int(), content="8")
  inspect(config_obj.get("max_batch").unwrap().as_number().unwrap().to_int(), content="3")
  inspect(config_obj.get("linger_ms").unwrap().as_number().unwrap().to_int(), content="25")
  inspect(config_obj.get("overflow").unwrap().as_string().unwrap(), content="DropOldest")
  inspect(config_obj.get("flush").unwrap().as_string().unwrap(), content="Batch")

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
  let formatter_obj = sink_obj.get("text_formatter").unwrap().as_object().unwrap()
  let async_obj = build_obj.get("async_config").unwrap().as_object().unwrap()

  inspect(logger_obj.get("min_level").unwrap().as_string().unwrap(), content="WARN")
  inspect(logger_obj.get("target").unwrap().as_string().unwrap(), content="async.roundtrip")
  inspect(logger_obj.get("timestamp").unwrap().as_bool().unwrap(), content="true")
  inspect(logger_obj.get("queue") is None, content="true")
  inspect(sink_obj.get("kind").unwrap().as_string().unwrap(), content="text_console")
  inspect(sink_obj.get("path").unwrap().as_string().unwrap(), content="")
  inspect(sink_obj.get("append").unwrap().as_bool().unwrap(), content="true")
  inspect(sink_obj.get("auto_flush").unwrap().as_bool().unwrap(), content="true")
  inspect(formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(), content="true")
  inspect(formatter_obj.get("separator").unwrap().as_string().unwrap(), content=" ")
  inspect(formatter_obj.get("field_separator").unwrap().as_string().unwrap(), content=" ")
  inspect(formatter_obj.get("template").unwrap().as_string().unwrap(), content="")
  inspect(formatter_obj.get("color_mode").unwrap().as_string().unwrap(), content="never")
  inspect(formatter_obj.get("color_support").unwrap().as_string().unwrap(), content="truecolor")
  inspect(formatter_obj.get("style_markup").unwrap().as_string().unwrap(), content="full")
  inspect(async_obj.get("max_pending").unwrap().as_number().unwrap().to_int(), content="2")
  inspect(async_obj.get("max_batch").unwrap().as_number().unwrap().to_int(), content="5")
  inspect(async_obj.get("linger_ms").unwrap().as_number().unwrap().to_int(), content="40")
  inspect(async_obj.get("overflow").unwrap().as_string().unwrap(), content="DropNewest")
  inspect(async_obj.get("flush").unwrap().as_string().unwrap(), content="Shutdown")
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
    @json_parser.stringify(async_logger_state_to_json(state)),
    content=if async_runtime_supports_background_worker() {
      "{\"runtime\":{\"mode\":\"native_worker\",\"background_worker\":true},\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    } else {
      "{\"runtime\":{\"mode\":\"compatibility\",\"background_worker\":false},\"pending_count\":0,\"dropped_count\":0,\"is_closed\":false,\"is_running\":false,\"has_failed\":false,\"last_error\":\"\",\"flush_policy\":\"Shutdown\"}"
    },
  )
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

async test "library async new preserves config and flush failure contract" {
  let writes : Ref[Int] = Ref(0)
  let flushes : Ref[Int] = Ref(0)
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) {
      writes.val += 1
    }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
      max_batch=3,
      linger_ms=7,
      flush=AsyncFlushPolicy::Batch,
    ),
    min_level=@bitlogger.Level::Warn,
    target="async.lib.new",
    flush=fn(_) -> Int raise {
      flushes.val += 1
      raise TestFlushError("library new flush exploded")
    },
  )
  let full = logger.to_async_logger()

  inspect(logger.is_enabled(@bitlogger.Level::Error), content="true")
  inspect(logger.is_enabled(@bitlogger.Level::Info), content="false")
  inspect(full.target, content="async.lib.new")
  inspect(match full.flush_policy() {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Batch")
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

async test "library async context binding replaces stored field set" {
  let written_fields : Ref[Array[@bitlogger.Field]] = Ref([])
  let logger = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(rec) {
      written_fields.val = rec.fields
    }),
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

  let root_child = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) {

    }),
  ).child("worker")
  inspect(root_child.to_async_logger().target, content="worker")

  let keep_parent = LibraryAsyncLogger::new(
    @bitlogger.callback_sink(fn(_) {

    }),
    target="sdk",
  ).child("")
  inspect(keep_parent.to_async_logger().target, content="sdk")
}

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
  )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])

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
  )
    .with_context_fields([@bitlogger.field("service", "bitlogger")])

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
  )
    .bind([@bitlogger.field("service", "bitlogger")])

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
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")

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

async test "library async text logger unwrap keeps async helper surface" {
  let logger = build_library_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.lib.text.helpers",
        text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
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
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")

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

async test "build async logger keeps direct helper surface and runtime sink path" {
  let logger = build_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.direct.helpers",
        queue=Some(@bitlogger.QueueConfig::new(3, overflow=@bitlogger.QueueOverflowPolicy::DropNewest)),
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
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")
  inspect(match logger.sink {
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")

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
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")

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

async test "application text async logger keeps async helper surface" {
  let logger : ApplicationTextAsyncLogger = build_application_text_async_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.text_console(
        min_level=@bitlogger.Level::Warn,
        target="async.app.text.alias",
        text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
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
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")

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

async test "build async text logger keeps direct helper surface" {
  let logger = build_async_text_logger(
    AsyncLoggerBuildConfig::new(
      logger=@bitlogger.LoggerConfig::new(
        min_level=@bitlogger.Level::Warn,
        target="async.text.helpers",
        timestamp=true,
        sink=@bitlogger.SinkConfig::new(
          kind=@bitlogger.SinkKind::TextConsole,
          text_formatter=@bitlogger.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
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
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")

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
  inspect(match state.flush_policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }, content="Shutdown")

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
