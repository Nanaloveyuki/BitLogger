///|
test "application logger can be built from config text" {
  let logger = parse_and_build_application_logger(
    "{\"min_level\":\"warn\",\"target\":\"app.json\",\"sink\":{\"kind\":\"console\"}}",
  )
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.target, content="app.json")
}

///|
test "parsed application logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = parse_and_build_application_logger(
      "{\"min_level\":\"warn\",\"target\":\"app.json.default\",\"sink\":{\"kind\":\"console\"}}",
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
    target="app.json.override",
  )
  inspect(captured_target.val, content="app.json.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="app.json.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

///|
test "parsed application logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = parse_and_build_application_logger(
      "{\"min_level\":\"info\",\"target\":\"app.json.helpers\",\"sink\":{\"kind\":\"console\"}}",
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
  inspect(captured_targets.val[0], content="app.json.helpers")
  inspect(captured_targets.val[1], content="app.json.helpers")
  inspect(captured_targets.val[2], content="app.json.helpers")
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
test "application logger parse-build matches parsed direct builder behavior" {
  let raw = "{\"min_level\":\"warn\",\"target\":\"app.json.same-build\",\"timestamp\":true,\"queue\":{\"max_pending\":2,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}}"
  let application = parse_and_build_application_logger(raw)
  let configured = build_logger(parse_logger_config_text(raw))

  inspect(application.target, content=configured.target)
  inspect(application.timestamp == configured.timestamp, content="true")
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
test "parsed application logger keeps direct runtime helper surface" {
  let logger : ApplicationLogger = parse_and_build_application_logger(
    "{\"min_level\":\"warn\",\"target\":\"app.json.helpers\",\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"},\"sink\":{\"kind\":\"file\",\"path\":\"app-json-helpers.log\"}}",
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
