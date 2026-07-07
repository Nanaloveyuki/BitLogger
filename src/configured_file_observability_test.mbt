///|
test "configured logger exposes file sink observability helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-file.log",
        auto_flush=false,
        rotation=Some(file_rotation(64, max_backups=3)),
      ),
    ),
  )
  let state = logger.file_state()
  let runtime_state = logger.file_runtime_state()
  inspect(logger.file_available() == native_files_supported(), content="true")
  inspect(logger.file_path(), content="config-file.log")
  inspect(state.path, content="config-file.log")
  inspect(state.available == logger.file_available(), content="true")
  inspect(state.append == logger.file_append_mode(), content="true")
  inspect(state.auto_flush == logger.file_auto_flush(), content="true")
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="false")
  match runtime_state {
    Some(snapshot) => {
      inspect(snapshot.queued, content="false")
      inspect(snapshot.pending_count, content="0")
      inspect(snapshot.dropped_count, content="0")
      inspect(snapshot.file.path, content="config-file.log")
    }
    None => inspect(false, content="true")
  }
  inspect(logger.file_rotation_enabled(), content="true")
  match logger.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="64")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
  inspect(
    logger.file_open_failures(),
    content=if logger.file_available() { "0" } else { "1" },
  )
  inspect(logger.file_write_failures(), content="0")
  inspect(logger.file_flush_failures(), content="0")
  inspect(logger.file_rotation_failures(), content="0")
  ignore(logger.close())
}

///|
test "configured logger reports disabled rotation when file sink has none" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-no-rotation.log"),
    ),
  )
  inspect(logger.file_rotation_enabled(), content="false")
  inspect(logger.file_rotation_config() is None, content="true")
  match logger.file_runtime_state() {
    Some(snapshot) => inspect(snapshot.queued, content="false")
    None => inspect(false, content="true")
  }
  ignore(logger.close())
}

///|
test "configured non-file logger has no file runtime state" {
  let logger = build_logger(
    LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)),
  )
  inspect(logger.file_path_or_none() is None, content="true")
  inspect(logger.file_policy_or_none() is None, content="true")
  inspect(logger.file_default_policy_or_none() is None, content="true")
  inspect(logger.file_state_or_none() is None, content="true")
  inspect(logger.file_runtime_state() is None, content="true")
}

///|
test "configured file logger mirrors backend file capability" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-capability.log"),
    ),
  )
  inspect(logger.file_available() == native_files_supported(), content="true")
  match logger.file_path_or_none() {
    Some(path) => inspect(path, content="config-capability.log")
    None => inspect(false, content="true")
  }
  inspect(logger.file_policy_or_none() is None, content="false")
  inspect(logger.file_default_policy_or_none() is None, content="false")
  inspect(logger.file_state_or_none() is None, content="false")
  if logger.file_available() {
    inspect(logger.file_state().available, content="true")
    ignore(logger.close())
  } else {
    inspect(logger.file_state().available, content="false")
    inspect(logger.file_flush(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

///|
