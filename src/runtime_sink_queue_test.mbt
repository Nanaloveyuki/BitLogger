///|
test "build logger from config supports queued text console" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Debug,
      target="config.runtime",
      timestamp=true,
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(
          show_timestamp=false,
          separator=" | ",
        ),
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

///|
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

///|
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

///|
test "configured logger queue helpers stay aligned with runtime sink helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(
          show_timestamp=false,
          show_target=false,
        ),
      ),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  let sink = logger.sink

  logger.info("one")
  logger.info("two")
  logger.info("three")

  inspect(logger.pending_count() == sink.pending_count(), content="true")
  inspect(logger.dropped_count() == sink.dropped_count(), content="true")
  inspect(logger.drain(max_items=1) == sink.drain(max_items=1), content="true")
  inspect(logger.pending_count() == sink.pending_count(), content="true")
  inspect(logger.flush() == sink.flush(), content="true")
  inspect(logger.pending_count() == sink.pending_count(), content="true")
  inspect(logger.dropped_count() == sink.dropped_count(), content="true")
}

///|
test "runtime sink queue helpers forward direct queue state" {
  let sink = RuntimeSink::QueuedTextConsole(
    queued_sink(
      text_console_sink(text_formatter(show_timestamp=false, show_target=false)),
      max_pending=2,
      overflow=QueueOverflowPolicy::DropOldest,
    ),
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="runtime.queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  inspect(sink.drain(max_items=1), content="1")
  inspect(sink.pending_count(), content="1")
  inspect(sink.flush(), content="1")
  inspect(sink.pending_count(), content="0")
}

///|
test "runtime sink queued file drain counts queue consumption separately from file write success" {
  let sink = RuntimeSink::QueuedFile(
    queued_sink(
      file_sink("missing-dir/runtime-drain-unavailable.log", auto_flush=false),
      max_pending=4,
    ),
  )
  let logger = Logger::new(
    sink,
    min_level=Level::Info,
    target="runtime.queue.file.unavailable",
  )
  logger.info("one")
  logger.info("two")
  inspect(sink.file_available(), content="false")
  inspect(sink.pending_count(), content="2")
  inspect(sink.file_write_failures(), content="0")
  inspect(sink.drain(max_items=1), content="1")
  inspect(sink.pending_count(), content="1")
  inspect(sink.file_write_failures(), content="1")
  inspect(sink.flush(), content="1")
  inspect(sink.pending_count(), content="0")
  inspect(sink.file_write_failures(), content="2")
}
