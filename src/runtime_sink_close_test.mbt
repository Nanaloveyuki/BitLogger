///|
test "configured logger close stays aligned with runtime sink close" {
  let console_config = LoggerConfig::new(
    min_level=Level::Info,
    target="config.close.console",
    sink=SinkConfig::new(kind=SinkKind::Console),
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
  )
  let console_logger = build_logger(console_config)
  let console_sink = build_logger(console_config).sink
  console_logger.info("one")
  console_logger.info("two")
  inspect(console_logger.pending_count(), content="2")
  inspect(console_logger.close() == console_sink.close(), content="true")
  inspect(console_logger.pending_count(), content="0")

  let file_config = LoggerConfig::new(
    target="config.close.file",
    sink=SinkConfig::new(kind=SinkKind::File, path="logs/config-close.log"),
  )
  let file_logger = build_logger(file_config)
  let file_sink = build_logger(file_config).sink
  inspect(file_logger.close() == file_sink.close(), content="true")
}

///|
test "queued console close drains pending queue before reporting success" {
  let sink = RuntimeSink::QueuedConsole(
    queued_sink(
      console_sink(),
      max_pending=4,
      overflow=QueueOverflowPolicy::DropNewest,
    ),
  )
  let logger = Logger::new(
    sink,
    min_level=Level::Info,
    target="runtime.close.console",
  )
  logger.info("one")
  logger.info("two")
  inspect(sink.pending_count(), content="2")
  inspect(sink.close(), content="true")
  inspect(sink.pending_count(), content="0")
  inspect(sink.flush(), content="0")
}

///|
test "queued json console close drains pending queue before reporting success" {
  let sink = RuntimeSink::QueuedJsonConsole(
    queued_sink(
      json_console_sink(),
      max_pending=4,
      overflow=QueueOverflowPolicy::DropNewest,
    ),
  )
  let logger = Logger::new(
    sink,
    min_level=Level::Info,
    target="runtime.close.json",
  )
  logger.info("one")
  logger.info("two")
  inspect(sink.pending_count(), content="2")
  inspect(sink.close(), content="true")
  inspect(sink.pending_count(), content="0")
  inspect(sink.drain(), content="0")
}

///|
test "queued text console close drains pending queue before reporting success" {
  let sink = RuntimeSink::QueuedTextConsole(
    queued_sink(
      text_console_sink(text_formatter(show_timestamp=false, show_target=false)),
      max_pending=4,
      overflow=QueueOverflowPolicy::DropNewest,
    ),
  )
  let logger = Logger::new(
    sink,
    min_level=Level::Info,
    target="runtime.close.text",
  )
  logger.info("one")
  logger.info("two")
  inspect(sink.pending_count(), content="2")
  inspect(sink.close(), content="true")
  inspect(sink.pending_count(), content="0")
  inspect(sink.flush(), content="0")
}

///|
test "configured queued console close drains pending queue" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.close.queued.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  inspect(logger.pending_count(), content="2")
  inspect(logger.close(), content="true")
  inspect(logger.pending_count(), content="0")
}

///|
test "runtime sink queued file close drains queue before teardown" {
  let sink = RuntimeSink::QueuedFile(
    queued_sink(
      file_sink("logs/runtime-close-queued.log", auto_flush=false),
      max_pending=4,
    ),
  )
  let logger = Logger::new(
    sink,
    min_level=Level::Info,
    target="runtime.close.queued",
  )
  logger.info("one")
  logger.info("two")
  inspect(sink.pending_count(), content="2")
  if sink.file_available() {
    inspect(sink.close(), content="true")
    inspect(sink.pending_count(), content="0")
    inspect(sink.file_available(), content="false")
    inspect(sink.file_close(), content="false")
  } else {
    inspect(sink.close(), content="false")
    inspect(sink.pending_count(), content="0")
    inspect(sink.file_available(), content="false")
    inspect(sink.file_write_failures(), content="2")
    inspect(sink.file_close(), content="false")
  }
}
