///|
test "configured logger file setters stay aligned with runtime sink setters" {
  let logger = build_logger(
    LoggerConfig::new(
      target="config.file.setters.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-file-setters-delegate.log",
      ),
    ),
  )
  let sink = logger.sink

  inspect(
    logger.file_set_append_mode(false) == sink.file_set_append_mode(false),
    content="true",
  )
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(
    logger.file_set_auto_flush(false) == sink.file_set_auto_flush(false),
    content="true",
  )
  inspect(logger.file_auto_flush() == sink.file_auto_flush(), content="true")

  let rotation = Some(file_rotation(48, max_backups=3))
  inspect(
    logger.file_set_rotation(rotation) == sink.file_set_rotation(rotation),
    content="true",
  )
  inspect(
    logger.file_rotation_enabled() == sink.file_rotation_enabled(),
    content="true",
  )

  let logger_policy = logger.file_policy()
  let sink_policy = sink.file_policy()
  inspect(logger_policy.append == sink_policy.append, content="true")
  inspect(logger_policy.auto_flush == sink_policy.auto_flush, content="true")
  inspect(
    match logger_policy.rotation {
      Some(value) =>
        match sink_policy.rotation {
          Some(other) =>
            value.max_bytes == other.max_bytes &&
            value.max_backups == other.max_backups
          None => false
        }
      None => sink_policy.rotation is None
    },
    content="true",
  )

  inspect(
    logger.file_clear_rotation() == sink.file_clear_rotation(),
    content="true",
  )
  inspect(
    logger.file_rotation_enabled() == sink.file_rotation_enabled(),
    content="true",
  )
  inspect(
    logger.file_policy_matches_default() == sink.file_policy_matches_default(),
    content="true",
  )

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.setters.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink
  inspect(
    console_logger.file_set_append_mode(true) ==
    console_sink.file_set_append_mode(true),
    content="true",
  )
  inspect(
    console_logger.file_set_auto_flush(true) ==
    console_sink.file_set_auto_flush(true),
    content="true",
  )
  inspect(
    console_logger.file_set_rotation(rotation) ==
    console_sink.file_set_rotation(rotation),
    content="true",
  )
  inspect(
    console_logger.file_clear_rotation() == console_sink.file_clear_rotation(),
    content="true",
  )

  ignore(logger.close())
}

///|
test "configured logger file reopen helpers stay aligned with runtime sink helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-reopen-delegate.log",
      ),
    ),
  )
  let sink = logger.sink

  inspect(
    logger.file_set_append_mode(false) == sink.file_set_append_mode(false),
    content="true",
  )
  inspect(logger.file_reopen() == sink.file_reopen(), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(
    logger.file_reopen_append() == sink.file_reopen_append(),
    content="true",
  )
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(
    logger.file_reopen_truncate() == sink.file_reopen_truncate(),
    content="true",
  )
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(
    logger.file_set_append_mode(true) == sink.file_set_append_mode(true),
    content="true",
  )
  inspect(
    logger.file_reopen_with_current_policy() ==
    sink.file_reopen_with_current_policy(),
    content="true",
  )
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(
    logger.file_reopen(append=Some(false)) ==
    sink.file_reopen(append=Some(false)),
    content="true",
  )
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  let console_logger = build_logger(
    LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)),
  )
  let console_sink = console_logger.sink
  inspect(
    console_logger.file_reopen() == console_sink.file_reopen(),
    content="true",
  )
  inspect(
    console_logger.file_reopen_with_current_policy() ==
    console_sink.file_reopen_with_current_policy(),
    content="true",
  )
  inspect(
    console_logger.file_reopen_append() == console_sink.file_reopen_append(),
    content="true",
  )
  inspect(
    console_logger.file_reopen_truncate() == console_sink.file_reopen_truncate(),
    content="true",
  )

  ignore(logger.close())
}

///|
test "configured logger file reset helpers stay aligned with runtime sink helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-reset-delegate.log",
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(40, max_backups=2)),
      ),
    ),
  )
  let sink = logger.sink

  ignore(logger.file_set_append_mode(true))
  ignore(sink.file_set_append_mode(true))
  ignore(logger.file_set_auto_flush(true))
  ignore(sink.file_set_auto_flush(true))
  ignore(logger.file_set_rotation(None))
  ignore(sink.file_set_rotation(None))

  inspect(
    logger.file_reset_policy() == sink.file_reset_policy(),
    content="true",
  )
  inspect(
    logger.file_policy_matches_default() == sink.file_policy_matches_default(),
    content="true",
  )
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")
  inspect(logger.file_auto_flush() == sink.file_auto_flush(), content="true")

  inspect(
    logger.file_reset_failure_counters() == sink.file_reset_failure_counters(),
    content="true",
  )
  inspect(
    logger.file_open_failures() == sink.file_open_failures(),
    content="true",
  )
  inspect(
    logger.file_write_failures() == sink.file_write_failures(),
    content="true",
  )
  inspect(
    logger.file_flush_failures() == sink.file_flush_failures(),
    content="true",
  )
  inspect(
    logger.file_rotation_failures() == sink.file_rotation_failures(),
    content="true",
  )

  let console_logger = build_logger(
    LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)),
  )
  let console_sink = console_logger.sink
  inspect(
    console_logger.file_reset_policy() == console_sink.file_reset_policy(),
    content="true",
  )
  inspect(
    console_logger.file_reset_failure_counters() ==
    console_sink.file_reset_failure_counters(),
    content="true",
  )

  ignore(logger.close())
}

///|
