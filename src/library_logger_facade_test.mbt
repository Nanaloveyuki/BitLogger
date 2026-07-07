///|
test "library logger keeps a smaller stable facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = LibraryLogger::new(
      callback_sink(fn(rec) {
        captured_target.val = rec.target
        captured_message.val = rec.message
        captured_fields.val = rec.fields
      }),
      min_level=Level::Info,
      target="svc",
    )
    .with_context_fields([field("service", "bitlogger")])
    .child("worker")
  logger.info("ready", fields=[field("mode", "test")])
  inspect(captured_target.val, content="svc.worker")
  inspect(captured_message.val, content="ready")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[1].key, content="mode")
}

///|
test "library logger context binding unwraps to context sink shape" {
  let logger = LibraryLogger::new(
    console_sink(),
    min_level=Level::Warn,
    target="lib.ctx",
  ).with_context_fields([field("service", "bitlogger"), field("scope", "sdk")])
  let full = logger.to_logger()

  inspect(full.target, content="lib.ctx")
  inspect(full.timestamp, content="false")
  inspect(full.is_enabled(Level::Error), content="true")
  inspect(full.is_enabled(Level::Info), content="false")
  inspect(full.sink.context_fields.length(), content="2")
  inspect(full.sink.context_fields[0].key, content="service")
  inspect(full.sink.context_fields[0].value, content="bitlogger")
  inspect(full.sink.context_fields[1].key, content="scope")
  inspect(full.sink.context_fields[1].value, content="sdk")
}

///|
test "library logger bind matches context facade contract" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
      callback_sink(fn(rec) {
        captured_target.val = rec.target
        captured_timestamp.val = rec.timestamp_ms
        captured_fields.val = rec.fields
      }),
      min_level=Level::Warn,
      target="lib.bind",
    )
    .with_timestamp()
    .to_library_logger()
    .bind([field("service", "bitlogger")])
  let full = logger.to_logger()

  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.bind")
  inspect(full.timestamp, content="true")
  inspect(full.sink.context_fields.length(), content="1")
  inspect(full.sink.context_fields[0].key, content="service")
  inspect(full.sink.context_fields[0].value, content="bitlogger")

  logger.error("bound", fields=[field("mode", "test")])
  inspect(captured_target.val, content="lib.bind")
  inspect(captured_timestamp.val > 0UL, content="true")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")
}

///|
test "library logger with_target preserves facade state while replacing target" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = Logger::new(
      callback_sink(fn(rec) {
        captured_target.val = rec.target
        captured_timestamp.val = rec.timestamp_ms
      }),
      min_level=Level::Warn,
      target="lib.base",
    )
    .with_timestamp()
    .to_library_logger()
    .with_target("lib.retarget")
  let full = logger.to_logger()

  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.retarget")
  inspect(full.timestamp, content="true")

  logger.error("retargeted")
  inspect(captured_target.val, content="lib.retarget")
  inspect(captured_timestamp.val > 0UL, content="true")
}

///|
test "library logger child composes target through facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = Logger::new(
      callback_sink(fn(rec) {
        captured_target.val = rec.target
        captured_timestamp.val = rec.timestamp_ms
      }),
      min_level=Level::Warn,
      target="sdk",
    )
    .with_timestamp()
    .to_library_logger()
    .child("worker")
  let full = logger.to_logger()

  inspect(full.target, content="sdk.worker")
  inspect(full.timestamp, content="true")
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")

  logger.error("child")
  inspect(captured_target.val, content="sdk.worker")
  inspect(captured_timestamp.val > 0UL, content="true")

  let root_child = LibraryLogger::new(console_sink()).child("worker")
  inspect(root_child.to_logger().target, content="worker")

  let keep_parent = LibraryLogger::new(console_sink(), target="sdk").child("")
  inspect(keep_parent.to_logger().target, content="sdk")
}

///|
test "library logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = LibraryLogger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Warn,
    target="lib.default",
  ).with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="lib.override",
  )
  inspect(captured_target.val, content="lib.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="lib.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

///|
test "library logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = LibraryLogger::new(
    callback_sink(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
    }),
    min_level=Level::Info,
    target="lib.helpers",
  ).bind([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="lib.helpers")
  inspect(captured_targets.val[1], content="lib.helpers")
  inspect(captured_targets.val[2], content="lib.helpers")
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
test "library logger can unwrap to full logger when needed" {
  let base = LibraryLogger::new(
    console_sink(),
    min_level=Level::Warn,
    target="lib",
  )
  let full = base.to_logger().with_timestamp()
  inspect(base.is_enabled(Level::Error), content="true")
  inspect(base.is_enabled(Level::Info), content="false")
  inspect(full.timestamp, content="true")
  inspect(full.target, content="lib")
}

///|
test "default library logger mirrors shared sync defaults" {
  set_default_min_level(Level::Warn)
  set_default_target("lib.default")
  let logger = default_library_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.to_logger().target, content="lib.default")
}

///|
test "default library logger snapshots shared defaults at creation time" {
  set_default_min_level(Level::Warn)
  set_default_target("lib.before")
  let before = default_library_logger()

  set_default_min_level(Level::Debug)
  set_default_target("lib.after")
  let after = default_library_logger()

  inspect(before.is_enabled(Level::Error), content="true")
  inspect(before.is_enabled(Level::Info), content="false")
  inspect(before.to_logger().target, content="lib.before")

  inspect(after.is_enabled(Level::Error), content="true")
  inspect(after.is_enabled(Level::Info), content="true")
  inspect(after.to_logger().target, content="lib.after")
}

///|
