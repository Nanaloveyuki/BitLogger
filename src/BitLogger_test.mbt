///|
test "level filter works" {
  let logger = Logger::new(console_sink(), min_level=Level::Warn, target="test")
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
}

///|
test "context sink merges fields" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="ctx").with_context_fields([
      field("service", "bitlogger"),
    ],
  )
  let merged = [field("service", "bitlogger"), field("mode", "test")]
  inspect(merged.length(), content="2")
  inspect(merged[0].key, content="service")
  inspect(merged[1].key, content="mode")
  logger.info("hello", fields=[field("mode", "test")])
}

///|
test "fields helper builds field arrays ergonomically" {
  let items = fields([("service", "bitlogger"), ("mode", "test")])
  inspect(items.length(), content="2")
  inspect(items[0].key, content="service")
  inspect(items[0].value, content="bitlogger")
  inspect(items[1].key, content="mode")
  inspect(items[1].value, content="test")
}

///|
test "default logger can be reconfigured" {
  set_default_min_level(Level::Debug)
  set_default_target("global")
  let logger = default_logger()
  inspect(logger.min_level.label(), content="DEBUG")
  inspect(logger.target, content="global")
}

///|
test "default logger snapshots shared defaults at creation time" {
  set_default_min_level(Level::Warn)
  set_default_target("before")
  let before = default_logger()

  set_default_min_level(Level::Debug)
  set_default_target("after")
  let after = default_logger()

  inspect(before.is_enabled(Level::Error), content="true")
  inspect(before.is_enabled(Level::Info), content="false")
  inspect(before.target, content="before")

  inspect(after.is_enabled(Level::Error), content="true")
  inspect(after.is_enabled(Level::Info), content="true")
  inspect(after.target, content="after")
}

///|
test "logger can enable timestamps" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="time").with_timestamp()
  inspect(logger.timestamp, content="true")
}

///|
test "fanout sink can write to plain and json outputs" {
  let logger = Logger::new(
    fanout_sink(console_sink(), json_console_sink()),
    min_level=Level::Info,
    target="fanout",
  )
  inspect(logger.is_enabled(Level::Info), content="true")
  logger.info("hello", fields=[field("kind", "dual")])
}

///|
test "child logger composes target path" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="app").child(
    "worker",
  )
  inspect(logger.target, content="app.worker")
}

///|
test "logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Warn,
    target="sync.default",
  ).with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="sync.override",
  )
  inspect(captured_target.val, content="sync.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="sync.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

///|
test "logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
    }),
    min_level=Level::Trace,
    target="sync.helpers",
  ).with_context_fields([field("service", "bitlogger")])

  logger.trace("trace", fields=[field("mode", "trace")])
  logger.debug("debug", fields=[field("mode", "debug")])
  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="5")
  inspect(captured_levels.val[0], content="TRACE")
  inspect(captured_levels.val[1], content="DEBUG")
  inspect(captured_levels.val[2], content="INFO")
  inspect(captured_levels.val[3], content="WARN")
  inspect(captured_levels.val[4], content="ERROR")
  inspect(captured_targets.val.length(), content="5")
  inspect(captured_targets.val[0], content="sync.helpers")
  inspect(captured_targets.val[1], content="sync.helpers")
  inspect(captured_targets.val[2], content="sync.helpers")
  inspect(captured_targets.val[3], content="sync.helpers")
  inspect(captured_targets.val[4], content="sync.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[3].length(), content="2")
  inspect(captured_fields.val[4].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="trace")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="debug")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="info")
  inspect(captured_fields.val[3][0].key, content="service")
  inspect(captured_fields.val[3][1].value, content="warn")
  inspect(captured_fields.val[4][0].key, content="service")
  inspect(captured_fields.val[4][1].value, content="error")
}

///|
test "callback sink sees child target and context logger shape" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_field_count : Ref[Int] = Ref(0)
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = Logger::new(
      callback_sink(fn(rec) {
        captured_target.val = rec.target
        captured_message.val = rec.message
        captured_field_count.val = rec.fields.length()
        captured_timestamp.val = rec.timestamp_ms
      }),
      min_level=Level::Info,
      target="app",
    )
    .child("worker")
    .with_context_fields([field("service", "bitlogger")])
    .with_timestamp()
  logger.info("ready", fields=[field("mode", "test")])
  inspect(captured_target.val, content="app.worker")
  inspect(captured_message.val, content="ready")
  inspect(captured_field_count.val, content="2")
  inspect(captured_timestamp.val > 0UL, content="true")
}

///|
test "bind aliases context fields ergonomically" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="bind",
  ).bind(fields([("service", "bitlogger"), ("scope", "audit")]))
  logger.info("ready", fields=[field("mode", "test")])
  inspect(captured_target.val, content="bind")
  inspect(captured_message.val, content="ready")
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="scope")
  inspect(captured_fields.val[1].value, content="audit")
  inspect(captured_fields.val[2].key, content="mode")
  inspect(captured_fields.val[2].value, content="test")
}
