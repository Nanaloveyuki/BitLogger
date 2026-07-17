///|
test "configured logger can project to library logger" {
  let configured = build_logger(
    LoggerConfig::new(min_level=Level::Warn, target="lib.projected"),
  )
  let logger = configured.to_library_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.to_logger().target, content="lib.projected")
}

///|
test "logger projection preserves sync composition state through library facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let captured_fields : Ref[Array[Field]] = Ref([])
  let base = Logger::new(
      callback_sink(fn(rec) {
        captured_target.val = rec.target
        captured_timestamp.val = rec.timestamp_ms
        captured_fields.val = rec.fields
      }),
      min_level=Level::Warn,
      target="lib.projected.state",
    )
    .with_timestamp()
    .with_context_fields([field("service", "bitlogger")])
  let projected = base.to_library_logger()
  let full = projected.to_logger()

  inspect(projected.is_enabled(Level::Error), content="true")
  inspect(projected.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.projected.state")
  inspect(full.timestamp, content="true")
  full.error("boom", fields=[field("mode", "test")])
  inspect(captured_target.val, content="lib.projected.state")
  inspect(captured_timestamp.val > 0UL, content="true")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
}

///|
test "configured logger projection preserves runtime helpers through unwrap" {
  let projected = build_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="lib.projected.runtime",
      sink=SinkConfig::new(kind=SinkKind::Console),
      queue=Some(QueueConfig::new(3, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  ).to_library_logger()
  let full = projected.to_logger()

  inspect(projected.is_enabled(Level::Error), content="true")
  inspect(projected.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.projected.runtime")
  full.error("one")
  full.error("two")
  inspect(
    match full.sink {
      RuntimeSink::QueuedConsole(_) => "QueuedConsole"
      RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
      RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
      RuntimeSink::QueuedFile(_) => "QueuedFile"
      _ => "Other"
    },
    content="QueuedConsole",
  )
  inspect(full.sink.pending_count(), content="2")
  inspect(full.sink.dropped_count(), content="0")
  inspect(full.sink.drain(max_items=1), content="1")
  inspect(full.sink.pending_count(), content="1")
  inspect(full.sink.flush(), content="1")
  inspect(full.sink.pending_count(), content="0")
}

///|
test "configured logger projection preserves file runtime helpers through unwrap" {
  let configured = build_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="lib.projected.file",
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="logs/lib-projected-file.log",
      ),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  let projected = configured.to_library_logger()
  let full = projected.to_logger()

  inspect(projected.is_enabled(Level::Error), content="true")
  inspect(projected.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.projected.file")

  full.error("one")
  full.error("two")
  full.error("three")
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
  inspect(
    full.file_set_rotation(Some(file_rotation(36, max_backups=2))) ==
    configured.file_set_rotation(Some(file_rotation(36, max_backups=2))),
    content="true",
  )
  inspect(
    full.file_rotation_enabled() == configured.file_rotation_enabled(),
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
    full.file_clear_rotation() == configured.file_clear_rotation(),
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
  inspect(full.file_flush() == configured.file_flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")

  let was_available = configured.file_available()
  inspect(configured.file_close() == was_available, content="true")
  inspect(full.file_available(), content="false")
  inspect(configured.file_available(), content="false")
  inspect(full.file_close(), content="false")
}

///|
test "configured logger keeps broader logger composition surface" {
  let logger : ConfiguredLogger = build_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="configured.compose",
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let derived = logger.with_timestamp().child("worker")

  inspect(derived.target, content="configured.compose.worker")
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
}

///|
test "configured logger build supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = build_logger(
      LoggerConfig::new(
        min_level=Level::Warn,
        target="configured.default",
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
    target="configured.override",
  )
  inspect(captured_target.val, content="configured.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="configured.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

///|
test "configured logger build severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = build_logger(
      LoggerConfig::new(
        min_level=Level::Info,
        target="configured.helpers",
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
  inspect(captured_targets.val[0], content="configured.helpers")
  inspect(captured_targets.val[1], content="configured.helpers")
  inspect(captured_targets.val[2], content="configured.helpers")
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
