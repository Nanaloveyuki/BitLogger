///|
test "library logger can be built from configured runtime path" {
  let logger = build_library_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="lib.config",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let full = logger.to_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.config")
}

///|
test "library logger builder log supports per-call target override through facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = build_library_logger(
      LoggerConfig::new(
        min_level=Level::Warn,
        target="lib.config.default",
        sink=SinkConfig::new(kind=SinkKind::Console),
      ),
    )
    .to_logger()
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .to_library_logger()
    .bind([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="lib.config.override",
  )
  inspect(captured_target.val, content="lib.config.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="lib.config.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

///|
test "library logger builder severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = build_library_logger(
      LoggerConfig::new(
        min_level=Level::Info,
        target="lib.config.helpers",
        sink=SinkConfig::new(kind=SinkKind::Console),
      ),
    )
    .to_logger()
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .to_library_logger()
    .bind([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="lib.config.helpers")
  inspect(captured_targets.val[1], content="lib.config.helpers")
  inspect(captured_targets.val[2], content="lib.config.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

///|
test "library logger builder unwrap matches direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="lib.config.same-build",
    timestamp=true,
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
    sink=SinkConfig::new(kind=SinkKind::Console),
  )
  let logger = build_library_logger(config)
  let full = logger.to_logger()
  let configured = build_logger(config)

  inspect(full.target, content=configured.target)
  inspect(full.timestamp == configured.timestamp, content="true")
  inspect(
    logger.is_enabled(Level::Error) == configured.is_enabled(Level::Error),
    content="true",
  )
  inspect(
    logger.is_enabled(Level::Info) == configured.is_enabled(Level::Info),
    content="true",
  )
  let full_sink_kind = match full.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  let configured_sink_kind = match configured.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  inspect(full_sink_kind == configured_sink_kind, content="true")

  full.error("one")
  full.error("two")
  full.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(full.flush() == configured.flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")
}

///|
test "library logger builder unwrap preserves file runtime helpers" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="lib.file.same-build",
    sink=SinkConfig::new(kind=SinkKind::File, path="lib-file-same-build.log"),
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
  )
  let logger = build_library_logger(config)
  let full = logger.to_logger()
  let configured = build_logger(config)

  full.error("one")
  full.error("two")
  full.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(full.file_available() == configured.file_available(), content="true")
  inspect(
    full.file_append_mode() == configured.file_append_mode(),
    content="true",
  )
  inspect(
    full.file_auto_flush() == configured.file_auto_flush(),
    content="true",
  )

  let full_state = full.file_state()
  let configured_state = configured.file_state()
  inspect(full_state.path == configured_state.path, content="true")
  inspect(full_state.available == configured_state.available, content="true")
  inspect(full_state.append == configured_state.append, content="true")
  inspect(full_state.auto_flush == configured_state.auto_flush, content="true")
  inspect(
    full_state.open_failures == configured_state.open_failures,
    content="true",
  )
  inspect(
    full_state.write_failures == configured_state.write_failures,
    content="true",
  )
  inspect(
    full_state.flush_failures == configured_state.flush_failures,
    content="true",
  )
  inspect(
    full_state.rotation_failures == configured_state.rotation_failures,
    content="true",
  )

  match (full.file_runtime_state(), configured.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(full.file_flush() == configured.file_flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.file_close() == configured.file_close(), content="true")
}

///|
test "library logger builder unwrap preserves file controls" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="lib.file.controls.same-build",
    sink=SinkConfig::new(
      kind=SinkKind::File,
      path="lib-file-controls-same-build.log",
    ),
  )
  let logger = build_library_logger(config)
  let full = logger.to_logger()
  let configured = build_logger(config)

  inspect(
    full.file_set_append_mode(false) == configured.file_set_append_mode(false),
    content="true",
  )
  inspect(
    full.file_append_mode() == configured.file_append_mode(),
    content="true",
  )
  inspect(
    full.file_set_auto_flush(false) == configured.file_set_auto_flush(false),
    content="true",
  )
  inspect(
    full.file_auto_flush() == configured.file_auto_flush(),
    content="true",
  )

  let rotation = Some(file_rotation(48, max_backups=3))
  inspect(
    full.file_set_rotation(rotation) == configured.file_set_rotation(rotation),
    content="true",
  )
  inspect(
    full.file_rotation_enabled() == configured.file_rotation_enabled(),
    content="true",
  )

  let full_policy = full.file_policy()
  let configured_policy = configured.file_policy()
  inspect(full_policy.append == configured_policy.append, content="true")
  inspect(
    full_policy.auto_flush == configured_policy.auto_flush,
    content="true",
  )
  inspect(
    match full_policy.rotation {
      Some(value) =>
        match configured_policy.rotation {
          Some(other) =>
            value.max_bytes == other.max_bytes &&
            value.max_backups == other.max_backups
          None => false
        }
      None => configured_policy.rotation is None
    },
    content="true",
  )

  inspect(
    full.file_reopen_append() == configured.file_reopen_append(),
    content="true",
  )
  inspect(
    full.file_append_mode() == configured.file_append_mode(),
    content="true",
  )
  inspect(
    full.file_reopen_truncate() == configured.file_reopen_truncate(),
    content="true",
  )
  inspect(
    full.file_append_mode() == configured.file_append_mode(),
    content="true",
  )
  inspect(
    full.file_reopen_with_current_policy() ==
    configured.file_reopen_with_current_policy(),
    content="true",
  )

  inspect(
    full.file_clear_rotation() == configured.file_clear_rotation(),
    content="true",
  )
  inspect(
    full.file_rotation_enabled() == configured.file_rotation_enabled(),
    content="true",
  )
  inspect(
    full.file_policy_matches_default() ==
    configured.file_policy_matches_default(),
    content="true",
  )
  inspect(
    full.file_reset_policy() == configured.file_reset_policy(),
    content="true",
  )
  inspect(
    full.file_policy_matches_default() ==
    configured.file_policy_matches_default(),
    content="true",
  )
  inspect(
    full.file_reset_failure_counters() ==
    configured.file_reset_failure_counters(),
    content="true",
  )

  inspect(full.file_close() == configured.file_close(), content="true")
}

///|
