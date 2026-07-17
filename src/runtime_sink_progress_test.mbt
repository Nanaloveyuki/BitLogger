///|
test "configured logger progress helpers stay aligned with runtime sink helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.progress.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(
          show_timestamp=false,
          show_target=false,
        ),
      ),
      queue=Some(QueueConfig::new(3, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  let sink = logger.sink

  logger.info("one")
  logger.info("two")
  logger.info("three")

  let logger_drain = logger.drain_progress(max_items=1)
  inspect(logger_drain.queue_advanced_count, content="1")
  inspect(logger_drain.file_flush_step_count, content="0")
  inspect(logger_drain.queue_backed, content="true")
  inspect(logger_drain.file_backed, content="false")

  let sink_drain = sink.drain_progress(max_items=1)
  inspect(sink_drain.queue_advanced_count, content="1")
  inspect(sink_drain.file_flush_step_count, content="0")
  inspect(sink_drain.queue_backed, content="true")
  inspect(sink_drain.file_backed, content="false")

  let logger_flush = logger.flush_progress()
  inspect(logger_flush.queue_advanced_count, content="1")
  inspect(logger_flush.file_flush_step_count, content="0")
  inspect(logger_flush.queue_backed, content="true")
  inspect(logger_flush.file_backed, content="false")

  let sink_flush = sink.flush_progress()
  inspect(sink_flush.queue_advanced_count, content="0")
  inspect(sink_flush.file_flush_step_count, content="0")
  inspect(sink_flush.queue_backed, content="true")
  inspect(sink_flush.file_backed, content="false")
}

///|
test "runtime sink queued file progress helpers stay distinct from file flush outcome" {
  let sink = RuntimeSink::QueuedFile(
    queued_sink(
      file_sink(
        "missing-dir/runtime-progress-unavailable.log",
        auto_flush=false,
      ),
      max_pending=4,
    ),
  )
  let logger = Logger::new(
    sink,
    min_level=Level::Info,
    target="runtime.queue.file.progress.unavailable",
  )
  logger.info("one")
  logger.info("two")

  let drained = sink.drain_progress(max_items=1)
  inspect(drained.queue_advanced_count, content="1")
  inspect(drained.file_flush_step_count, content="0")
  inspect(drained.queue_backed, content="true")
  inspect(drained.file_backed, content="true")
  inspect(sink.pending_count(), content="1")
  inspect(sink.file_write_failures(), content="1")

  let flushed = sink.flush_progress()
  inspect(flushed.queue_advanced_count, content="1")
  inspect(flushed.file_flush_step_count, content="0")
  inspect(flushed.queue_backed, content="true")
  inspect(flushed.file_backed, content="true")
  inspect(sink.pending_count(), content="0")
  inspect(sink.file_write_failures(), content="2")
  inspect(sink.file_flush(), content="false")
}

///|
test "runtime sink progress helpers expose queue and plain file steps separately" {
  let console_sink = RuntimeSink::Console(console_sink())
  let console_progress = console_sink.flush_progress()
  inspect(console_progress.queue_advanced_count, content="0")
  inspect(console_progress.file_flush_step_count, content="0")
  inspect(console_progress.queue_backed, content="false")
  inspect(console_progress.file_backed, content="false")

  let queued_sink = RuntimeSink::QueuedTextConsole(
    queued_sink(
      text_console_sink(text_formatter(show_timestamp=false, show_target=false)),
      max_pending=4,
      overflow=QueueOverflowPolicy::DropNewest,
    ),
  )
  let queued_logger = Logger::new(
    queued_sink,
    min_level=Level::Info,
    target="runtime.progress.queue.text",
  )
  queued_logger.info("one")
  let queued_progress = queued_sink.flush_progress()
  inspect(queued_progress.queue_advanced_count, content="1")
  inspect(queued_progress.file_flush_step_count, content="0")
  inspect(queued_progress.queue_backed, content="true")
  inspect(queued_progress.file_backed, content="false")

  let file_sink = RuntimeSink::File(
    file_sink("logs/runtime-progress-direct.log", auto_flush=false),
  )
  let file_progress = file_sink.flush_progress()
  inspect(file_progress.queue_advanced_count, content="0")
  inspect(file_progress.queue_backed, content="false")
  inspect(file_progress.file_backed, content="true")
  if file_sink.file_available() {
    inspect(file_progress.file_flush_step_count, content="1")
    inspect(file_sink.close(), content="true")
  } else {
    inspect(file_progress.file_flush_step_count, content="0")
    inspect(file_sink.close(), content="false")
  }
}

///|
