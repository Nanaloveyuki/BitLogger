///|
fn main {
  let logger = @lib.build_logger(
    @lib.text_console(
      min_level=@lib.Level::Info,
      target="demo.style",
      text_formatter=@lib.TextFormatterConfig::new(
        show_timestamp=false,
        color_mode=@lib.ColorMode::Always,
        style_tags={ "accent": @lib.text_style(fg=Some("#4cc9f0"), bold=true) },
      ),
    ),
  )
  logger.info("<accent>styled</> output with <danger>alert</>")
}
