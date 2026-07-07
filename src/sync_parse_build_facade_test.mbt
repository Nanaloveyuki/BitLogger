///|
test "parsed configured logger keeps composition and runtime helper surface" {
  let logger : ConfiguredLogger = parse_and_build_logger(
    "{\"min_level\":\"warn\",\"target\":\"parsed.compose\",\"timestamp\":true,\"queue\":{\"max_pending\":2,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}}",
  )
  let derived = logger.child("worker")

  inspect(derived.target, content="parsed.compose.worker")
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
test "parsed configured logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = parse_and_build_logger(
      "{\"min_level\":\"warn\",\"target\":\"parsed.default\",\"sink\":{\"kind\":\"console\"}}",
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
    target="parsed.override",
  )
  inspect(captured_target.val, content="parsed.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="parsed.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

///|
test "parsed configured logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = parse_and_build_logger(
      "{\"min_level\":\"info\",\"target\":\"parsed.helpers\",\"sink\":{\"kind\":\"console\"}}",
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
  inspect(captured_targets.val[0], content="parsed.helpers")
  inspect(captured_targets.val[1], content="parsed.helpers")
  inspect(captured_targets.val[2], content="parsed.helpers")
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
test "sync parse-build facades forward config errors" {
  let raw = "{\"sink\":{\"kind\":\"file\",\"path\":\"\"}}"
  let malformed = "{"

  let configured_error = (fn() -> String raise ConfigError {
    ignore(parse_and_build_logger(raw))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(configured_error, content="File sink requires non-empty path")

  let application_error = (fn() -> String raise ConfigError {
    ignore(parse_and_build_application_logger(raw))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(application_error, content="File sink requires non-empty path")

  let library_error = (fn() -> String raise ConfigError {
    ignore(parse_and_build_library_logger(raw))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(library_error, content="File sink requires non-empty path")

  let configured_invalid_json = (fn() -> String raise ConfigError {
    ignore(parse_and_build_logger(malformed))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(configured_invalid_json.contains("Invalid JSON:"), content="true")

  let application_invalid_json = (fn() -> String raise ConfigError {
    ignore(parse_and_build_application_logger(malformed))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(application_invalid_json.contains("Invalid JSON:"), content="true")

  let library_invalid_json = (fn() -> String raise ConfigError {
    ignore(parse_and_build_library_logger(malformed))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(library_invalid_json.contains("Invalid JSON:"), content="true")
}
