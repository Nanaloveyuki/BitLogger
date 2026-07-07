///|
test "runtime sink plain variants use documented fallback counts" {
  let console_sink = RuntimeSink::Console(console_sink())
  inspect(console_sink.pending_count(), content="0")
  inspect(console_sink.dropped_count(), content="0")
  inspect(console_sink.flush(), content="0")
  inspect(console_sink.drain(), content="0")

  let file_sink = RuntimeSink::File(
    file_sink("runtime-direct.log", auto_flush=false),
  )
  inspect(file_sink.pending_count(), content="0")
  inspect(file_sink.dropped_count(), content="0")
  if file_sink.file_available() {
    inspect(file_sink.flush(), content="1")
    inspect(file_sink.drain(), content="1")
    inspect(file_sink.close(), content="true")
  } else {
    inspect(file_sink.flush(), content="0")
    inspect(file_sink.drain(), content="0")
    inspect(file_sink.close(), content="false")
  }
}

///|
test "runtime sink non-file variants expose documented file fallbacks" {
  let sink = RuntimeSink::Console(console_sink())
  inspect(sink.file_available(), content="false")
  inspect(sink.file_path_or_none() is None, content="true")
  inspect(sink.file_path(), content="")
  inspect(sink.file_append_mode(), content="false")
  inspect(sink.file_auto_flush(), content="false")
  inspect(sink.file_rotation_enabled(), content="false")
  inspect(sink.file_rotation_config() is None, content="true")
  inspect(sink.file_open_failures(), content="0")
  inspect(sink.file_write_failures(), content="0")
  inspect(sink.file_flush_failures(), content="0")
  inspect(sink.file_rotation_failures(), content="0")
  inspect(sink.file_reopen(), content="false")
  inspect(sink.file_reopen_with_current_policy(), content="false")
  inspect(sink.file_reopen_append(), content="false")
  inspect(sink.file_reopen_truncate(), content="false")
  inspect(sink.file_set_append_mode(true), content="false")
  inspect(sink.file_set_auto_flush(true), content="false")
  inspect(
    sink.file_set_rotation(Some(file_rotation(32, max_backups=2))),
    content="false",
  )
  inspect(sink.file_clear_rotation(), content="false")
  inspect(sink.file_set_policy(FileSinkPolicy::new()), content="false")
  inspect(sink.file_reset_failure_counters(), content="false")
  inspect(sink.file_reset_policy(), content="false")
  inspect(sink.file_flush(), content="false")
  inspect(sink.file_close(), content="false")
  inspect(sink.file_policy_or_none() is None, content="true")
  inspect(sink.file_default_policy_or_none() is None, content="true")
  let policy = sink.file_policy()
  let defaults = sink.file_default_policy()
  inspect(sink.file_state_or_none() is None, content="true")
  let state = sink.file_state()
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  inspect(policy.rotation is None, content="true")
  inspect(defaults.append, content="false")
  inspect(defaults.auto_flush, content="false")
  inspect(defaults.rotation is None, content="true")
  inspect(sink.file_policy_matches_default(), content="false")
  inspect(state.path, content="")
  inspect(state.available, content="false")
  inspect(state.append, content="false")
  inspect(state.auto_flush, content="false")
  inspect(state.rotation is None, content="true")
  inspect(state.open_failures, content="0")
  inspect(state.write_failures, content="0")
  inspect(state.flush_failures, content="0")
  inspect(state.rotation_failures, content="0")
  inspect(sink.file_runtime_state() is None, content="true")
}

///|
test "runtime sink plain file helpers expose direct file state and policy" {
  let sink = RuntimeSink::File(
    file_sink(
      "runtime-file-helpers.log",
      auto_flush=false,
      rotation=Some(file_rotation(40, max_backups=2)),
    ),
  )
  inspect(sink.file_available() == native_files_supported(), content="true")
  match sink.file_path_or_none() {
    Some(path) => inspect(path, content="runtime-file-helpers.log")
    None => inspect(false, content="true")
  }
  inspect(sink.file_path(), content="runtime-file-helpers.log")
  inspect(sink.file_append_mode(), content="true")
  inspect(sink.file_auto_flush(), content="false")
  inspect(sink.file_rotation_enabled(), content="true")
  match sink.file_default_policy_or_none() {
    Some(policy) => {
      inspect(policy.append, content="true")
      inspect(policy.auto_flush, content="false")
    }
    None => inspect(false, content="true")
  }
  match sink.file_policy_or_none() {
    Some(policy) => {
      inspect(policy.append, content="true")
      inspect(policy.auto_flush, content="false")
    }
    None => inspect(false, content="true")
  }
  let defaults = sink.file_default_policy()
  let policy = sink.file_policy()
  inspect(defaults.append, content="true")
  inspect(defaults.auto_flush, content="false")
  inspect(policy.append, content="true")
  inspect(policy.auto_flush, content="false")
  inspect(sink.file_policy_matches_default(), content="true")
  match sink.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="40")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  match sink.file_state_or_none() {
    Some(snapshot) => {
      inspect(snapshot.path, content="runtime-file-helpers.log")
      inspect(snapshot.append, content="true")
      inspect(snapshot.auto_flush, content="false")
    }
    None => inspect(false, content="true")
  }
  let state = sink.file_state()
  inspect(state.path, content="runtime-file-helpers.log")
  inspect(state.available == sink.file_available(), content="true")
  inspect(state.append, content="true")
  inspect(state.auto_flush, content="false")
  match sink.file_runtime_state() {
    Some(snapshot) => {
      inspect(snapshot.queued, content="false")
      inspect(snapshot.pending_count, content="0")
      inspect(snapshot.dropped_count, content="0")
      inspect(snapshot.file.path, content="runtime-file-helpers.log")
    }
    None => inspect(false, content="true")
  }
  inspect(sink.file_set_append_mode(false), content="true")
  inspect(sink.file_set_auto_flush(true), content="true")
  inspect(sink.file_clear_rotation(), content="true")
  inspect(sink.file_policy_matches_default(), content="false")
  inspect(sink.file_append_mode(), content="false")
  inspect(sink.file_auto_flush(), content="true")
  inspect(sink.file_rotation_config() is None, content="true")
  inspect(sink.file_reset_policy(), content="true")
  inspect(sink.file_policy_matches_default(), content="true")
  inspect(sink.file_append_mode(), content="true")
  inspect(sink.file_auto_flush(), content="false")
  inspect(sink.file_rotation_enabled(), content="true")
  if sink.file_available() {
    inspect(sink.file_flush(), content="true")
    inspect(sink.file_close(), content="true")
  } else {
    inspect(sink.file_flush(), content="false")
    inspect(sink.file_close(), content="false")
  }
}

///|
test "runtime sink queued file helpers preserve queue-aware file runtime state" {
  let sink = RuntimeSink::QueuedFile(
    queued_sink(
      file_sink("runtime-queued-file.log", auto_flush=false),
      max_pending=2,
      overflow=QueueOverflowPolicy::DropNewest,
    ),
  )
  let logger = Logger::new(
    sink,
    min_level=Level::Info,
    target="runtime.file.queue",
  )
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.file_available() == native_files_supported(), content="true")
  match sink.file_path_or_none() {
    Some(path) => inspect(path, content="runtime-queued-file.log")
    None => inspect(false, content="true")
  }
  inspect(sink.file_path(), content="runtime-queued-file.log")
  inspect(sink.file_policy_or_none() is None, content="false")
  inspect(sink.file_default_policy_or_none() is None, content="false")
  inspect(sink.file_state_or_none() is None, content="false")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  match sink.file_runtime_state() {
    Some(snapshot) => {
      inspect(snapshot.queued, content="true")
      inspect(snapshot.pending_count, content="2")
      inspect(snapshot.dropped_count, content="1")
      inspect(snapshot.file.path, content="runtime-queued-file.log")
    }
    None => inspect(false, content="true")
  }
  if sink.file_available() {
    inspect(sink.file_flush(), content="true")
    inspect(sink.pending_count(), content="0")
    match sink.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(sink.file_close(), content="true")
  } else {
    inspect(sink.file_flush(), content="false")
    inspect(sink.pending_count(), content="0")
    match sink.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(sink.file_close(), content="false")
  }
}

///|
