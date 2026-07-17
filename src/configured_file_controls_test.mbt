///|
test "configured logger file setters update file sink policy state" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="logs/config-setters.log"),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let default_policy = logger.file_default_policy()
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="true")
  inspect(logger.file_rotation_enabled(), content="false")
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(logger.file_policy_matches_default(), content="true")
  inspect(logger.file_set_append_mode(false), content="true")
  inspect(logger.file_append_mode(), content="false")
  inspect(logger.file_set_auto_flush(false), content="true")
  inspect(logger.file_auto_flush(), content="false")
  inspect(
    logger.file_set_rotation(Some(file_rotation(48, max_backups=4))),
    content="true",
  )
  inspect(logger.file_rotation_enabled(), content="true")
  match logger.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="48")
      inspect(rotation.max_backups, content="4")
    }
    None => inspect(false, content="true")
  }
  inspect(logger.file_clear_rotation(), content="true")
  inspect(logger.file_rotation_enabled(), content="false")
  inspect(logger.file_rotation_config() is None, content="true")
  inspect(
    logger.file_reopen(),
    content=if logger.file_available() { "true" } else { "false" },
  )
  inspect(logger.file_append_mode(), content="false")
  let state = logger.file_state()
  let policy = logger.file_policy()
  inspect(state.append, content="false")
  inspect(state.auto_flush, content="false")
  inspect(state.rotation is None, content="true")
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  inspect(policy.rotation is None, content="true")
  inspect(logger.file_policy_matches_default(), content="false")
  inspect(logger.file_reset_policy(), content="true")
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="true")
  inspect(logger.file_rotation_config() is None, content="true")
  inspect(logger.file_policy_matches_default(), content="true")
  ignore(logger.close())
}

///|
test "configured logger reset policy restores configured file defaults" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-reset-policy.log",
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(36, max_backups=2)),
      ),
    ),
  )
  let default_policy = logger.file_default_policy()
  inspect(default_policy.append, content="false")
  inspect(default_policy.auto_flush, content="false")
  inspect(logger.file_policy_matches_default(), content="true")
  inspect(logger.file_set_append_mode(true), content="true")
  inspect(logger.file_set_auto_flush(true), content="true")
  inspect(logger.file_clear_rotation(), content="true")
  inspect(logger.file_reset_policy(), content="true")
  inspect(logger.file_append_mode(), content="false")
  inspect(logger.file_auto_flush(), content="false")
  inspect(logger.file_policy_matches_default(), content="true")
  match logger.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="36")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  ignore(logger.close())
}

///|
test "configured logger set policy applies bundled runtime file policy" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-set-policy.log",
      ),
    ),
  )
  let default_policy = logger.file_default_policy()
  inspect(
    logger.file_set_policy(
      FileSinkPolicy::new(
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(22, max_backups=3)),
      ),
    ),
    content="true",
  )
  let policy = logger.file_policy()
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  match policy.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="22")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(logger.file_policy_matches_default(), content="false")
  ignore(logger.close())
}

///|
test "configured non-file logger cannot reset file policy" {
  let logger = build_logger(
    LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)),
  )
  inspect(logger.file_reset_policy(), content="false")
  inspect(logger.file_policy().append, content="false")
  inspect(logger.file_default_policy().append, content="false")
  inspect(logger.file_set_policy(FileSinkPolicy::new()), content="false")
  inspect(logger.file_policy_matches_default(), content="false")
}

///|
test "configured logger can reopen built file sink" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="logs/config-reopen.log"),
    ),
  )
  if logger.file_available() {
    inspect(logger.close(), content="true")
    inspect(logger.file_reopen_append(), content="true")
    inspect(logger.file_available(), content="true")
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_open_failures(), content="0")
    logger.info("reopened from config")
    inspect(logger.file_write_failures(), content="0")
    inspect(logger.file_reopen_truncate(), content="true")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen(), content="true")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen_with_current_policy(), content="true")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen_append(), content="true")
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_reset_failure_counters(), content="true")
    inspect(logger.file_open_failures(), content="0")
    inspect(logger.file_write_failures(), content="0")
    inspect(logger.file_flush_failures(), content="0")
    inspect(logger.file_rotation_failures(), content="0")
    inspect(logger.close(), content="true")
  } else {
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_open_failures(), content="1")
    logger.info("dropped")
    inspect(logger.file_write_failures(), content="1")
    inspect(logger.file_reopen_append(), content="false")
    inspect(logger.file_open_failures(), content="2")
    inspect(logger.file_reopen_truncate(), content="false")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen_with_current_policy(), content="false")
    inspect(logger.file_open_failures(), content="4")
    inspect(logger.file_reopen_append(), content="false")
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_open_failures(), content="5")
    inspect(logger.file_reset_failure_counters(), content="true")
    inspect(logger.file_open_failures(), content="0")
    inspect(logger.file_write_failures(), content="0")
    inspect(logger.file_flush_failures(), content="0")
    inspect(logger.file_rotation_failures(), content="0")
  }
}

///|
test "configured non-file logger cannot reset file failure counters" {
  let logger = build_logger(
    LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)),
  )
  inspect(logger.file_reset_failure_counters(), content="false")
}

///|
test "configured logger exposes file flush and close helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="logs/config-control.log"),
    ),
  )
  if logger.file_available() {
    logger.info("before flush")
    inspect(logger.file_flush(), content="true")
    inspect(logger.file_close(), content="true")
    inspect(logger.file_available(), content="false")
    inspect(logger.file_flush(), content="false")
  } else {
    inspect(logger.file_flush(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

///|
test "configured queued file logger flushes queue through file helper" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-queued-file.log",
      ),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  match logger.file_runtime_state() {
    Some(snapshot) => {
      inspect(snapshot.queued, content="true")
      inspect(snapshot.pending_count, content="2")
      inspect(snapshot.dropped_count, content="0")
    }
    None => inspect(false, content="true")
  }
  if logger.file_available() {
    inspect(logger.pending_count(), content="2")
    inspect(logger.file_flush(), content="true")
    inspect(logger.pending_count(), content="0")
    match logger.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(logger.file_close(), content="true")
  } else {
    inspect(logger.pending_count(), content="2")
    inspect(logger.file_flush(), content="false")
    inspect(logger.pending_count(), content="0")
    match logger.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(logger.file_close(), content="false")
  }
}

///|
test "configured queued file logger blocks policy mutation while queue is pending" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-queued-policy.log",
      ),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  inspect(logger.pending_count(), content="2")
  inspect(logger.file_set_append_mode(false), content="false")
  inspect(logger.file_append_mode(), content="true")
  inspect(
    logger.file_set_policy(
      FileSinkPolicy::new(append=false, auto_flush=false, rotation=None),
    ),
    content="false",
  )
  inspect(logger.file_reopen_truncate(), content="false")
  inspect(logger.pending_count(), content="2")
  if logger.file_available() {
    inspect(logger.file_flush(), content="true")
    inspect(logger.pending_count(), content="0")
    inspect(logger.file_set_append_mode(false), content="true")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen_with_current_policy(), content="true")
    inspect(logger.file_close(), content="true")
  } else {
    inspect(logger.file_flush(), content="false")
    inspect(logger.pending_count(), content="0")
    inspect(logger.file_reopen_with_current_policy(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

///|
test "configured queued file logger close drains queue before teardown" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-close-queued.log",
      ),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  inspect(logger.pending_count(), content="2")
  if logger.file_available() {
    inspect(logger.close(), content="true")
    inspect(logger.pending_count(), content="0")
    inspect(logger.file_available(), content="false")
    inspect(logger.file_close(), content="false")
  } else {
    inspect(logger.close(), content="false")
    inspect(logger.pending_count(), content="0")
    inspect(logger.file_available(), content="false")
    inspect(logger.file_write_failures(), content="2")
    inspect(logger.file_close(), content="false")
  }
}
