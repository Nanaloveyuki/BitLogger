fn main {
  let formatter = @lib.text_formatter(
    show_timestamp=false,
    separator=" | ",
    field_separator=",",
    template="[{level}] {target} {message} :: {fields}",
  )
  let logger = @lib.Logger::new(
    @lib.text_console_sink(formatter),
    min_level=@lib.Level::Info,
    target="demo.formatter",
  )
  logger.info("formatted output", fields=[@lib.field("user", "alice"), @lib.field("request_id", "42")])
}
