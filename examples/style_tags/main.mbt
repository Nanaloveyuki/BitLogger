fn main {
  let formatter = @lib.text_formatter(
    show_timestamp=false,
    color_mode=@lib.ColorMode::Always,
  ).with_style_tags(
    @lib.default_style_tag_registry()
      .set_tag("accent", fg=Some("#4cc9f0"), bold=true)
      .define_alias("danger", "red"),
  )
  let logger = @lib.Logger::new(
    @lib.text_console_sink(formatter),
    min_level=@lib.Level::Info,
    target="demo.style",
  )
  logger.info("<accent>styled</> output with <danger>alert</>")
}
