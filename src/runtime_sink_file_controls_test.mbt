///|
test "runtime sink plain file reopen helpers and failure resets work directly" {
  let sink = RuntimeSink::File(file_sink("runtime-reopen-direct.log"))
  if sink.file_available() {
    inspect(sink.close(), content="true")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_available(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="0")
    Logger::new(sink, min_level=Level::Info, target="runtime.reopen.direct").info(
      "reopened",
    )
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_reopen_truncate(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
    inspect(sink.close(), content="true")
  } else {
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="1")
    Logger::new(sink, min_level=Level::Info, target="runtime.reopen.direct").info(
      "dropped",
    )
    inspect(sink.file_write_failures(), content="1")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_open_failures(), content="2")
    inspect(sink.file_reopen_truncate(), content="false")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="false")
    inspect(sink.file_open_failures(), content="4")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="5")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
  }
}

///|
test "runtime sink queued file reopen helpers and failure resets work directly" {
  let sink = RuntimeSink::QueuedFile(
    queued_sink(file_sink("runtime-reopen-queued.log"), max_pending=2),
  )
  if sink.file_available() {
    inspect(sink.file_close(), content="true")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_available(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="0")
    let logger = Logger::new(
      sink,
      min_level=Level::Info,
      target="runtime.reopen.queued",
    )
    logger.info("one")
    logger.info("two")
    inspect(sink.pending_count(), content="2")
    inspect(sink.file_reopen_truncate(), content="false")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_set_append_mode(false), content="false")
    inspect(sink.file_append_mode(), content="true")
    inspect(
      sink.file_set_policy(
        FileSinkPolicy::new(append=false, auto_flush=false, rotation=None),
      ),
      content="false",
    )
    inspect(sink.pending_count(), content="2")
    inspect(sink.file_flush(), content="true")
    inspect(sink.pending_count(), content="0")
    inspect(sink.file_reopen_truncate(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
    inspect(sink.file_close(), content="true")
  } else {
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="1")
    let logger = Logger::new(
      sink,
      min_level=Level::Info,
      target="runtime.reopen.queued",
    )
    logger.info("one")
    inspect(sink.pending_count(), content="1")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_set_append_mode(false), content="false")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_flush(), content="false")
    inspect(sink.pending_count(), content="0")
    inspect(sink.file_write_failures(), content="1")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_open_failures(), content="2")
    inspect(sink.file_reopen_truncate(), content="false")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="false")
    inspect(sink.file_open_failures(), content="4")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="5")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
  }
}

///|
