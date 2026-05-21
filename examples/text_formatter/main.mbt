fn main {
  let logger = @lib.build_logger(
    @lib.text_console(
      min_level=@lib.Level::Info,
      target="demo.formatter",
      text_formatter=@lib.TextFormatterConfig::new(
        show_timestamp=false,
        separator=" | ",
        field_separator=",",
        template="[{level}] {target} {message} :: {fields}",
      ),
    ),
  )
  logger.info("formatted output", fields=[@lib.field("user", "alice"), @lib.field("request_id", "42")])
}
