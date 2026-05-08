fn main {
  @lib.set_default_min_level(@lib.Level::Debug)
  @lib.set_default_target("bitlogger")
  @lib.info("hello from BitLogger", fields=[@lib.field("mode", "demo")])

  let logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Trace, target="custom")
    .with_context_fields([@lib.field("service", "bitlogger")])
  logger.debug("custom logger ready", fields=[@lib.field("sink", "console")])

  let json_logger = @lib.Logger::new(@lib.json_console_sink(), min_level=@lib.Level::Info, target="json")
  json_logger.info("json output", fields=[@lib.field("kind", "example")])

  let fanout_logger = @lib.Logger::new(
    @lib.fanout_sink(@lib.console_sink(), @lib.json_console_sink()),
    min_level=@lib.Level::Info,
    target="fanout",
  )
  fanout_logger.info("dual output", fields=[@lib.field("kind", "fanout")])

  let timed_logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Info, target="timed")
    .with_timestamp()
  timed_logger.info("timestamp enabled", fields=[@lib.field("kind", "time")])

  let child_logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Info, target="app")
    .child("worker")
  child_logger.info("child target ready")

  let callback_logger = @lib.Logger::new(
    @lib.callback_sink(fn(rec) {
      println("callback saw [\{rec.target}] \{rec.message}")
    }),
    min_level=@lib.Level::Info,
    target="hook",
  )
  callback_logger.info("callback sink ready")
}
