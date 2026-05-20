fn main {
  let logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Info, target="demo.console")
    .with_context_fields([@lib.field("service", "bitlogger")])
  logger.info("hello console", fields=[@lib.field("mode", "basic")])

  let structured = @lib.Logger::new(@lib.json_console_sink(), min_level=@lib.Level::Info, target="demo.json")
  structured.info("hello json", fields=[@lib.field("kind", "structured")])
}
