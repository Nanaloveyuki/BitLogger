async test "shutdown drains pending records" {
  let written : Ref[Array[String]] = Ref::new([])
  let logger = async_logger(
    @bitlogger.callback_sink(fn(rec) {
      written.val.push(rec.message)
    }),
    config=AsyncLoggerConfig::new(
      max_pending=4,
      overflow=AsyncOverflowPolicy::Blocking,
    ),
    min_level=@bitlogger.Level::Info,
    target="async.test",
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
  inspect(written.val.length(), content="2")
  inspect(written.val[0], content="one")
  inspect(written.val[1], content="two")
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
    ),
  )
  let config = parse_async_logger_config_text(text)
  inspect(config.max_pending, content="8")
  inspect(match config.overflow {
    AsyncOverflowPolicy::Blocking => "Blocking"
    AsyncOverflowPolicy::DropOldest => "DropOldest"
    AsyncOverflowPolicy::DropNewest => "DropNewest"
  }, content="DropOldest")
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
      ),
    ),
  )
  let config = parse_async_logger_build_config_text(text)
  inspect(config.logger.min_level.label(), content="WARN")
  inspect(config.logger.target, content="async.roundtrip")
  inspect(config.logger.timestamp, content="true")
  inspect(config.async_config.max_pending, content="2")
  inspect(match config.async_config.overflow {
    AsyncOverflowPolicy::Blocking => "Blocking"
    AsyncOverflowPolicy::DropOldest => "DropOldest"
    AsyncOverflowPolicy::DropNewest => "DropNewest"
  }, content="DropNewest")
}
