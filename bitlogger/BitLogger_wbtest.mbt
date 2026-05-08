test "default logger can be reconfigured" {
  set_default_min_level(Level::Debug)
  set_default_target("global")
  let logger = default_logger()
  inspect(logger.min_level.label(), content="DEBUG")
  inspect(logger.target, content="global")
}

test "logger can enable timestamps" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="time")
    .with_timestamp()
  inspect(logger.timestamp, content="true")
}

test "callback sink receives record" {
  let captured_target : Ref[String] = Ref::new("")
  let captured_message : Ref[String] = Ref::new("")
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
    }),
    min_level=Level::Info,
    target="callback",
  )
  logger.info("hello")
  inspect(captured_target.val, content="callback")
  inspect(captured_message.val, content="hello")
}

test "callback sink sees child target and context logger shape" {
  let captured_target : Ref[String] = Ref::new("")
  let captured_message : Ref[String] = Ref::new("")
  let captured_field_count : Ref[Int] = Ref::new(0)
  let captured_timestamp : Ref[UInt64] = Ref::new(0UL)
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
