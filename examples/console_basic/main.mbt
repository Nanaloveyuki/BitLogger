///|
fn main {
  let logger = @lib.build_logger(
    @lib.console(min_level=@lib.Level::Info, target="demo.console"),
  )
  logger.info("hello console", fields=[@lib.field("mode", "basic")])

  let structured = @lib.build_logger(
    @lib.json_console(min_level=@lib.Level::Info, target="demo.json"),
  )
  structured.info("hello json", fields=[@lib.field("kind", "structured")])
}
