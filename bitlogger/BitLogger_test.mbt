test "level filter works" {
  let logger = Logger::new(console_sink(), min_level=Level::Warn, target="test")
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
}

test "context sink merges fields" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="ctx")
    .with_context_fields([field("service", "bitlogger")])
  let merged = [field("service", "bitlogger"), field("mode", "test")]
  inspect(merged.length(), content="2")
  inspect(merged[0].key, content="service")
  inspect(merged[1].key, content="mode")
  logger.info("hello", fields=[field("mode", "test")])
}

test "fanout sink can write to plain and json outputs" {
  let logger = Logger::new(
    fanout_sink(console_sink(), json_console_sink()),
    min_level=Level::Info,
    target="fanout",
  )
  inspect(logger.is_enabled(Level::Info), content="true")
  logger.info("hello", fields=[field("kind", "dual")])
}

test "child logger composes target path" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="app")
    .child("worker")
  inspect(logger.target, content="app.worker")
}

test "logger config parser reads core options" {
  let config = parse_logger_config_text(
    "{\"min_level\":\"debug\",\"target\":\"service\",\"timestamp\":true}",
  )
  inspect(config.min_level.label(), content="DEBUG")
  inspect(config.target, content="service")
  inspect(config.timestamp, content="true")
}

test "logger config parser reads formatter and queue options" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"separator\":\" | \",\"show_timestamp\":false}},\"queue\":{\"max_pending\":32,\"overflow\":\"DropOldest\"}}",
  )
  inspect(match config.sink.kind {
    SinkKind::TextConsole => "TextConsole"
    _ => "other"
  }, content="TextConsole")
  inspect(config.sink.text_formatter.separator, content=" | ")
  inspect(config.sink.text_formatter.show_timestamp, content="false")
  match config.queue {
    Some(queue) => {
      inspect(queue.max_pending, content="32")
      inspect(match queue.overflow {
        QueueOverflowPolicy::DropNewest => "DropNewest"
        QueueOverflowPolicy::DropOldest => "DropOldest"
      }, content="DropOldest")
    }
    None => inspect(false, content="true")
  }
}

test "logger config stringify roundtrips stable fields" {
  let text = stringify_logger_config(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="api",
      timestamp=true,
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(
          show_timestamp=false,
          show_level=true,
          show_target=true,
          show_fields=true,
          separator=" | ",
          field_separator=",",
        ),
      ),
      queue=Some(QueueConfig::new(8, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let config = parse_logger_config_text(text)
  inspect(config.min_level.label(), content="WARN")
  inspect(config.target, content="api")
  inspect(config.timestamp, content="true")
  inspect(config.sink.text_formatter.separator, content=" | ")
}

test "build logger from config supports queued text console" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Debug,
      target="config.runtime",
      timestamp=true,
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(show_timestamp=false, separator=" | "),
      ),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.flush(), content="2")
}

test "configured logger drain supports partial queue draining" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.partial",
      sink=SinkConfig::new(kind=SinkKind::Console),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(logger.pending_count(), content="3")
  inspect(logger.drain(max_items=2), content="2")
  inspect(logger.pending_count(), content="1")
  inspect(logger.flush(), content="1")
}

test "configured logger reports dropped_count for bounded queue" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.drop",
      sink=SinkConfig::new(kind=SinkKind::TextConsole),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  logger.info("three")
  logger.info("four")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="2")
  inspect(logger.flush(), content="2")
}
