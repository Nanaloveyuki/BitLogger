async test "shutdown drains pending records" {
  inspect(async_runtime_mode_label(async_runtime_mode()) == "native_worker" || async_runtime_mode_label(async_runtime_mode()) == "compatibility", content="true")
  let written : Ref[Array[String]] = Ref::new([])
  let flushes : Ref[Int] = Ref::new(0)
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

async test "run drains queued records in compatibility backends too" {
  let written : Ref[Array[String]] = Ref::new([])
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
