///|
test "logger config stringify roundtrips stable fields" {
  let text = stringify_logger_config(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="api",
      timestamp=true,
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(
          show_timestamp=false,
          show_level=true,
          show_target=true,
          show_fields=true,
          separator=" | ",
          field_separator=",",
          template="[{level}] {target} {message}",
        ),
      ),
      queue=Some(QueueConfig::new(8, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let config = parse_logger_config_text(text)
  inspect(config.min_level.label(), content="WARN")
  inspect(config.target, content="api")
  inspect(config.timestamp, content="true")
  inspect(config.sink.text_formatter.separator, content=" | ")
  inspect(
    config.sink.text_formatter.template,
    content="[{level}] {target} {message}",
  )
}

///|
test "logger config stringify roundtrips formatter style tags" {
  let text = stringify_logger_config(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(
          color_mode=ColorMode::Always,
          color_support=ColorSupport::Basic,
          style_markup=StyleMarkupMode::Builtin,
          target_style_markup=StyleMarkupMode::Builtin,
          fields_style_markup=StyleMarkupMode::Disabled,
          style_tags={
            "accent": text_style(fg=Some("#4cc9f0"), bold=true),
            "panel": text_style(bg=Some("#202020"), dim=true),
          },
        ),
      ),
    ),
  )
  let config = parse_logger_config_text(text)
  inspect(
    color_mode_label(config.sink.text_formatter.color_mode),
    content="always",
  )
  inspect(
    color_support_label(config.sink.text_formatter.color_support),
    content="basic",
  )
  inspect(
    style_markup_mode_label(config.sink.text_formatter.style_markup),
    content="builtin",
  )
  inspect(
    style_markup_mode_label(config.sink.text_formatter.target_style_markup),
    content="builtin",
  )
  inspect(
    style_markup_mode_label(config.sink.text_formatter.fields_style_markup),
    content="disabled",
  )
  inspect(config.sink.text_formatter.style_tags.length(), content="2")
  inspect(
    config.sink.text_formatter.style_tags.get("accent").unwrap().fg.unwrap(),
    content="#4cc9f0",
  )
  inspect(
    config.sink.text_formatter.style_tags.get("accent").unwrap().bold,
    content="true",
  )
  inspect(
    config.sink.text_formatter.style_tags.get("panel").unwrap().bg.unwrap(),
    content="#202020",
  )
  inspect(
    config.sink.text_formatter.style_tags.get("panel").unwrap().dim,
    content="true",
  )
}

///|
