test "level filter works" {
  let logger = Logger::new(console_sink(), min_level=Level::Warn, target="test")
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
}

test "context sink merges fields" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="ctx")
    .with_context_fields([field("service", "bitlogger")])
  let merged = [field("service", "bitlogger"), field("mode", "test")]
  inspect(merged.length(), content="2")
  inspect(merged[0].key, content="service")
  inspect(merged[1].key, content="mode")
  logger.info("hello", fields=[field("mode", "test")])
}

test "fanout sink can write to plain and json outputs" {
  let logger = Logger::new(
    fanout_sink(console_sink(), json_console_sink()),
    min_level=Level::Info,
    target="fanout",
  )
  inspect(logger.is_enabled(Level::Info), content="true")
  logger.info("hello", fields=[field("kind", "dual")])
}

test "child logger composes target path" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="app")
    .child("worker")
  inspect(logger.target, content="app.worker")
}
