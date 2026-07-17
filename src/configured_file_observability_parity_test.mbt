///|
test "configured logger file observation helpers stay aligned with runtime sink helpers" {
  let file_logger = build_logger(
    LoggerConfig::new(
      target="config.file.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-file-delegate.log",
      ),
    ),
  )
  let file_sink = file_logger.sink

  inspect(
    file_logger.file_available() == file_sink.file_available(),
    content="true",
  )
  inspect(file_logger.file_path() == file_sink.file_path(), content="true")
  inspect(
    file_logger.file_open_failures() == file_sink.file_open_failures(),
    content="true",
  )
  inspect(
    file_logger.file_write_failures() == file_sink.file_write_failures(),
    content="true",
  )
  inspect(
    file_logger.file_flush_failures() == file_sink.file_flush_failures(),
    content="true",
  )
  inspect(
    file_logger.file_rotation_failures() == file_sink.file_rotation_failures(),
    content="true",
  )

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.delegate.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink

  inspect(
    console_logger.file_available() == console_sink.file_available(),
    content="true",
  )
  inspect(
    console_logger.file_path() == console_sink.file_path(),
    content="true",
  )
  inspect(
    console_logger.file_open_failures() == console_sink.file_open_failures(),
    content="true",
  )
  inspect(
    console_logger.file_write_failures() == console_sink.file_write_failures(),
    content="true",
  )
  inspect(
    console_logger.file_flush_failures() == console_sink.file_flush_failures(),
    content="true",
  )
  inspect(
    console_logger.file_rotation_failures() ==
    console_sink.file_rotation_failures(),
    content="true",
  )

  ignore(file_logger.close())
}

///|
test "configured logger file policy helpers stay aligned with runtime sink helpers" {
  let file_logger = build_logger(
    LoggerConfig::new(
      target="config.file.policy.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-file-policy-delegate.log",
        append=false,
        auto_flush=true,
        rotation=Some(file_rotation(64, max_backups=2)),
      ),
    ),
  )
  let file_sink = file_logger.sink
  let file_policy = file_logger.file_policy()
  let file_sink_policy = file_sink.file_policy()
  let file_defaults = file_logger.file_default_policy()
  let file_sink_defaults = file_sink.file_default_policy()
  let file_policy_has_rotation = match file_policy.rotation {
    Some(_) => true
    None => false
  }
  let file_sink_policy_has_rotation = match file_sink_policy.rotation {
    Some(_) => true
    None => false
  }
  let file_defaults_has_rotation = match file_defaults.rotation {
    Some(_) => true
    None => false
  }
  let file_sink_defaults_has_rotation = match file_sink_defaults.rotation {
    Some(_) => true
    None => false
  }

  inspect(
    file_logger.file_append_mode() == file_sink.file_append_mode(),
    content="true",
  )
  inspect(
    file_logger.file_auto_flush() == file_sink.file_auto_flush(),
    content="true",
  )
  inspect(
    file_logger.file_rotation_enabled() == file_sink.file_rotation_enabled(),
    content="true",
  )
  inspect(
    file_logger.file_policy_matches_default() ==
    file_sink.file_policy_matches_default(),
    content="true",
  )
  inspect(file_policy.append == file_sink_policy.append, content="true")
  inspect(file_policy.auto_flush == file_sink_policy.auto_flush, content="true")
  inspect(
    file_policy_has_rotation == file_sink_policy_has_rotation,
    content="true",
  )
  inspect(file_defaults.append == file_sink_defaults.append, content="true")
  inspect(
    file_defaults.auto_flush == file_sink_defaults.auto_flush,
    content="true",
  )
  inspect(
    file_defaults_has_rotation == file_sink_defaults_has_rotation,
    content="true",
  )

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.policy.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink
  let console_policy = console_logger.file_policy()
  let console_sink_policy = console_sink.file_policy()
  let console_defaults = console_logger.file_default_policy()
  let console_sink_defaults = console_sink.file_default_policy()
  let console_policy_has_rotation = match console_policy.rotation {
    Some(_) => true
    None => false
  }
  let console_sink_policy_has_rotation = match console_sink_policy.rotation {
    Some(_) => true
    None => false
  }
  let console_defaults_has_rotation = match console_defaults.rotation {
    Some(_) => true
    None => false
  }
  let console_sink_defaults_has_rotation = match
    console_sink_defaults.rotation {
    Some(_) => true
    None => false
  }

  inspect(
    console_logger.file_append_mode() == console_sink.file_append_mode(),
    content="true",
  )
  inspect(
    console_logger.file_auto_flush() == console_sink.file_auto_flush(),
    content="true",
  )
  inspect(
    console_logger.file_rotation_enabled() ==
    console_sink.file_rotation_enabled(),
    content="true",
  )
  inspect(
    console_logger.file_policy_matches_default() ==
    console_sink.file_policy_matches_default(),
    content="true",
  )
  inspect(console_policy.append == console_sink_policy.append, content="true")
  inspect(
    console_policy.auto_flush == console_sink_policy.auto_flush,
    content="true",
  )
  inspect(
    console_policy_has_rotation == console_sink_policy_has_rotation,
    content="true",
  )
  inspect(
    console_defaults.append == console_sink_defaults.append,
    content="true",
  )
  inspect(
    console_defaults.auto_flush == console_sink_defaults.auto_flush,
    content="true",
  )
  inspect(
    console_defaults_has_rotation == console_sink_defaults_has_rotation,
    content="true",
  )

  ignore(file_logger.close())
}

///|
test "configured logger file flush and close stay aligned with runtime sink helpers" {
  let file_config = LoggerConfig::new(
    sink=SinkConfig::new(
      kind=SinkKind::File,
      path="logs/config-file-helper-delegate.log",
    ),
  )
  let file_logger = build_logger(file_config)
  let file_sink = build_logger(file_config).sink

  inspect(file_logger.file_flush() == file_sink.file_flush(), content="true")
  inspect(file_logger.file_close() == file_sink.file_close(), content="true")

  let console_config = LoggerConfig::new(
    sink=SinkConfig::new(kind=SinkKind::Console),
  )
  let console_logger = build_logger(console_config)
  let console_sink = build_logger(console_config).sink

  inspect(
    console_logger.file_flush() == console_sink.file_flush(),
    content="true",
  )
  inspect(
    console_logger.file_close() == console_sink.file_close(),
    content="true",
  )
}

///|
test "configured logger file state helpers stay aligned with runtime sink helpers" {
  let file_logger = build_logger(
    LoggerConfig::new(
      target="config.file.state.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-file-state-delegate.log",
      ),
    ),
  )
  let file_sink = file_logger.sink
  let file_state = file_logger.file_state()
  let file_sink_state = file_sink.file_state()

  inspect(file_state.path == file_sink_state.path, content="true")
  inspect(file_state.available == file_sink_state.available, content="true")
  inspect(file_state.append == file_sink_state.append, content="true")
  inspect(file_state.auto_flush == file_sink_state.auto_flush, content="true")
  inspect(
    file_state.open_failures == file_sink_state.open_failures,
    content="true",
  )
  inspect(
    file_state.write_failures == file_sink_state.write_failures,
    content="true",
  )
  inspect(
    file_state.flush_failures == file_sink_state.flush_failures,
    content="true",
  )
  inspect(
    file_state.rotation_failures == file_sink_state.rotation_failures,
    content="true",
  )
  inspect(
    match file_state.rotation {
      Some(rotation) =>
        match file_sink_state.rotation {
          Some(other) =>
            rotation.max_bytes == other.max_bytes &&
            rotation.max_backups == other.max_backups
          None => false
        }
      None => file_sink_state.rotation is None
    },
    content="true",
  )
  inspect(
    (file_logger.file_runtime_state() is None) ==
    (file_sink.file_runtime_state() is None),
    content="true",
  )

  let queued_logger = build_logger(
    LoggerConfig::new(
      target="config.file.runtime.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/config-file-runtime-delegate.log",
      ),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let queued_sink = queued_logger.sink
  queued_logger.info("one")
  queued_logger.info("two")
  let queued_state = queued_logger.file_state()
  let queued_sink_state = queued_sink.file_state()

  inspect(queued_state.path == queued_sink_state.path, content="true")
  inspect(queued_state.available == queued_sink_state.available, content="true")
  inspect(queued_state.append == queued_sink_state.append, content="true")
  inspect(
    queued_state.auto_flush == queued_sink_state.auto_flush,
    content="true",
  )
  inspect(
    queued_state.open_failures == queued_sink_state.open_failures,
    content="true",
  )
  inspect(
    queued_state.write_failures == queued_sink_state.write_failures,
    content="true",
  )
  inspect(
    queued_state.flush_failures == queued_sink_state.flush_failures,
    content="true",
  )
  inspect(
    queued_state.rotation_failures == queued_sink_state.rotation_failures,
    content="true",
  )
  inspect(
    match queued_state.rotation {
      Some(rotation) =>
        match queued_sink_state.rotation {
          Some(other) =>
            rotation.max_bytes == other.max_bytes &&
            rotation.max_backups == other.max_backups
          None => false
        }
      None => queued_sink_state.rotation is None
    },
    content="true",
  )

  match (queued_logger.file_runtime_state(), queued_sink.file_runtime_state()) {
    (Some(snapshot), Some(sink_snapshot)) => {
      inspect(snapshot.file.path == sink_snapshot.file.path, content="true")
      inspect(
        snapshot.file.available == sink_snapshot.file.available,
        content="true",
      )
      inspect(snapshot.file.append == sink_snapshot.file.append, content="true")
      inspect(
        snapshot.file.auto_flush == sink_snapshot.file.auto_flush,
        content="true",
      )
      inspect(
        snapshot.file.open_failures == sink_snapshot.file.open_failures,
        content="true",
      )
      inspect(
        snapshot.file.write_failures == sink_snapshot.file.write_failures,
        content="true",
      )
      inspect(
        snapshot.file.flush_failures == sink_snapshot.file.flush_failures,
        content="true",
      )
      inspect(
        snapshot.file.rotation_failures == sink_snapshot.file.rotation_failures,
        content="true",
      )
      inspect(snapshot.queued == sink_snapshot.queued, content="true")
      inspect(
        snapshot.pending_count == sink_snapshot.pending_count,
        content="true",
      )
      inspect(
        snapshot.dropped_count == sink_snapshot.dropped_count,
        content="true",
      )
      inspect(
        match snapshot.file.rotation {
          Some(rotation) =>
            match sink_snapshot.file.rotation {
              Some(other) =>
                rotation.max_bytes == other.max_bytes &&
                rotation.max_backups == other.max_backups
              None => false
            }
          None => sink_snapshot.file.rotation is None
        },
        content="true",
      )
    }
    _ => inspect(false, content="true")
  }

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.state.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink
  let console_state = console_logger.file_state()
  let console_sink_state = console_sink.file_state()

  inspect(console_state.path == console_sink_state.path, content="true")
  inspect(
    console_state.available == console_sink_state.available,
    content="true",
  )
  inspect(console_state.append == console_sink_state.append, content="true")
  inspect(
    console_state.auto_flush == console_sink_state.auto_flush,
    content="true",
  )
  inspect(
    console_state.open_failures == console_sink_state.open_failures,
    content="true",
  )
  inspect(
    console_state.write_failures == console_sink_state.write_failures,
    content="true",
  )
  inspect(
    console_state.flush_failures == console_sink_state.flush_failures,
    content="true",
  )
  inspect(
    console_state.rotation_failures == console_sink_state.rotation_failures,
    content="true",
  )
  inspect(
    (console_state.rotation is None) == (console_sink_state.rotation is None),
    content="true",
  )
  inspect(
    (console_logger.file_runtime_state() is None) ==
    (console_sink.file_runtime_state() is None),
    content="true",
  )

  ignore(file_logger.close())
  ignore(queued_logger.close())
}

///|
