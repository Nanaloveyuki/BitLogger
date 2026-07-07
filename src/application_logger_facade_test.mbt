///|
test "application logger aliases configured runtime entry" {
  let logger = build_application_logger(
    LoggerConfig::new(min_level=Level::Warn, target="app.runtime"),
  )
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.target, content="app.runtime")
}

///|
test "application logger builder matches direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="app.runtime.same-build",
    timestamp=true,
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
    sink=SinkConfig::new(kind=SinkKind::Console),
  )
  let application = build_application_logger(config)
  let configured = build_logger(config)

  inspect(application.target, content=configured.target)
  inspect(application.timestamp, content="true")
  inspect(configured.timestamp, content="true")
  inspect(
    application.is_enabled(Level::Error) == configured.is_enabled(Level::Error),
    content="true",
  )
  inspect(
    application.is_enabled(Level::Info) == configured.is_enabled(Level::Info),
    content="true",
  )
  let application_sink_kind = match application.sink {
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
  inspect(application_sink_kind == configured_sink_kind, content="true")

  application.error("one")
  application.error("two")
  application.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(
    application.pending_count() == configured.pending_count(),
    content="true",
  )
  inspect(
    application.dropped_count() == configured.dropped_count(),
    content="true",
  )
  inspect(application.flush() == configured.flush(), content="true")
  inspect(
    application.pending_count() == configured.pending_count(),
    content="true",
  )
}

///|
test "application logger keeps configured runtime helper surface" {
  let logger : ApplicationLogger = build_application_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="app.alias.helpers",
      sink=SinkConfig::new(kind=SinkKind::File, path="app-alias.log"),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )

  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.file_policy().append, content="true")
  inspect(logger.file_runtime_state() is None, content="false")
  inspect(logger.flush(), content="2")
  inspect(logger.pending_count(), content="0")

  if logger.file_available() {
    inspect(logger.file_flush(), content="true")
    inspect(logger.file_close(), content="true")
  } else {
    inspect(logger.file_flush(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

///|
test "application logger build supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = build_application_logger(
      LoggerConfig::new(
        min_level=Level::Warn,
        target="app.config.default",
        sink=SinkConfig::new(kind=SinkKind::Console),
      ),
    )
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="app.config.override",
  )
  inspect(captured_target.val, content="app.config.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="app.config.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

///|
test "application logger build severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = build_application_logger(
      LoggerConfig::new(
        min_level=Level::Info,
        target="app.config.helpers",
        sink=SinkConfig::new(kind=SinkKind::Console),
      ),
    )
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="app.config.helpers")
  inspect(captured_targets.val[1], content="app.config.helpers")
  inspect(captured_targets.val[2], content="app.config.helpers")
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
test "application logger keeps broader logger composition surface" {
  let logger : ApplicationLogger = build_application_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="app.compose",
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let derived = logger.with_timestamp().child("worker")

  inspect(derived.target, content="app.compose.worker")
  inspect(derived.timestamp, content="true")
  inspect(derived.is_enabled(Level::Error), content="true")
  inspect(derived.is_enabled(Level::Info), content="false")
  inspect(
    match derived.sink {
      RuntimeSink::QueuedConsole(_) => "QueuedConsole"
      RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
      RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
      RuntimeSink::QueuedFile(_) => "QueuedFile"
      _ => "Other"
    },
    content="QueuedConsole",
  )

  derived.error("one")
  derived.error("two")
  inspect(derived.pending_count(), content="2")
  inspect(derived.dropped_count(), content="0")
  inspect(derived.flush(), content="2")
  inspect(derived.pending_count(), content="0")
}

///|
test "application logger file helpers match direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="app.file.same-build",
    sink=SinkConfig::new(kind=SinkKind::File, path="app-file-same-build.log"),
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
  )
  let application = build_application_logger(config)
  let configured = build_logger(config)

  application.error("one")
  application.error("two")
  application.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(
    application.pending_count() == configured.pending_count(),
    content="true",
  )
  inspect(
    application.dropped_count() == configured.dropped_count(),
    content="true",
  )
  inspect(
    application.file_available() == configured.file_available(),
    content="true",
  )
  inspect(
    application.file_append_mode() == configured.file_append_mode(),
    content="true",
  )
  inspect(
    application.file_auto_flush() == configured.file_auto_flush(),
    content="true",
  )
  inspect(
    application.file_policy_matches_default() ==
    configured.file_policy_matches_default(),
    content="true",
  )

  let application_policy = application.file_policy()
  let configured_policy = configured.file_policy()
  inspect(application_policy.append == configured_policy.append, content="true")
  inspect(
    application_policy.auto_flush == configured_policy.auto_flush,
    content="true",
  )
  inspect(
    match application_policy.rotation {
      Some(rotation) =>
        match configured_policy.rotation {
          Some(other) =>
            rotation.max_bytes == other.max_bytes &&
            rotation.max_backups == other.max_backups
          None => false
        }
      None => configured_policy.rotation is None
    },
    content="true",
  )

  let application_state = application.file_state()
  let configured_state = configured.file_state()
  inspect(application_state.path == configured_state.path, content="true")
  inspect(
    application_state.available == configured_state.available,
    content="true",
  )
  inspect(application_state.append == configured_state.append, content="true")
  inspect(
    application_state.auto_flush == configured_state.auto_flush,
    content="true",
  )
  inspect(
    application_state.open_failures == configured_state.open_failures,
    content="true",
  )
  inspect(
    application_state.write_failures == configured_state.write_failures,
    content="true",
  )
  inspect(
    application_state.flush_failures == configured_state.flush_failures,
    content="true",
  )
  inspect(
    application_state.rotation_failures == configured_state.rotation_failures,
    content="true",
  )

  match (application.file_runtime_state(), configured.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(application.file_flush() == configured.file_flush(), content="true")
  inspect(
    application.pending_count() == configured.pending_count(),
    content="true",
  )
  inspect(application.file_close() == configured.file_close(), content="true")
}

///|
test "application logger file controls match direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="app.file.controls.same-build",
    sink=SinkConfig::new(
      kind=SinkKind::File,
      path="app-file-controls-same-build.log",
    ),
  )
  let application = build_application_logger(config)
  let configured = build_logger(config)

  inspect(
    application.file_set_append_mode(false) ==
    configured.file_set_append_mode(false),
    content="true",
  )
  inspect(
    application.file_append_mode() == configured.file_append_mode(),
    content="true",
  )

  inspect(
    application.file_set_auto_flush(false) ==
    configured.file_set_auto_flush(false),
    content="true",
  )
  inspect(
    application.file_auto_flush() == configured.file_auto_flush(),
    content="true",
  )

  let rotation = Some(file_rotation(48, max_backups=3))
  inspect(
    application.file_set_rotation(rotation) ==
    configured.file_set_rotation(rotation),
    content="true",
  )
  inspect(
    application.file_rotation_enabled() == configured.file_rotation_enabled(),
    content="true",
  )

  let application_policy = application.file_policy()
  let configured_policy = configured.file_policy()
  inspect(application_policy.append == configured_policy.append, content="true")
  inspect(
    application_policy.auto_flush == configured_policy.auto_flush,
    content="true",
  )
  inspect(
    match application_policy.rotation {
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
    application.file_reopen_append() == configured.file_reopen_append(),
    content="true",
  )
  inspect(
    application.file_append_mode() == configured.file_append_mode(),
    content="true",
  )
  inspect(
    application.file_reopen_truncate() == configured.file_reopen_truncate(),
    content="true",
  )
  inspect(
    application.file_append_mode() == configured.file_append_mode(),
    content="true",
  )
  inspect(
    application.file_reopen_with_current_policy() ==
    configured.file_reopen_with_current_policy(),
    content="true",
  )

  inspect(
    application.file_clear_rotation() == configured.file_clear_rotation(),
    content="true",
  )
  inspect(
    application.file_rotation_enabled() == configured.file_rotation_enabled(),
    content="true",
  )
  inspect(
    application.file_policy_matches_default() ==
    configured.file_policy_matches_default(),
    content="true",
  )
  inspect(
    application.file_reset_policy() == configured.file_reset_policy(),
    content="true",
  )
  inspect(
    application.file_policy_matches_default() ==
    configured.file_policy_matches_default(),
    content="true",
  )
  inspect(
    application.file_reset_failure_counters() ==
    configured.file_reset_failure_counters(),
    content="true",
  )

  inspect(application.file_close() == configured.file_close(), content="true")
}

///|
