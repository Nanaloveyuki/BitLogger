///|
test "config basic color support downgrades hex colors" {
  let formatter = TextFormatterConfig::new(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    color_support=ColorSupport::Basic,
  )
  let rendered = format_text(
    Record::new(Level::Info, "<#ff0000>hot</> <bg:#010203>bg</>"),
    formatter=formatter.to_formatter(),
  )
  inspect(
    rendered,
    content="\u{001b}[31mhot\u{001b}[0m \u{001b}[100mbg\u{001b}[0m",
  )
}

///|
test "config formatter style tags render in built logger" {
  let formatter = TextFormatterConfig::new(
    show_timestamp=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_tags={ "accent": text_style(fg=Some("#4cc9f0"), bold=true) },
  )
  let rendered = format_text(
    Record::new(Level::Info, "<accent>tag</>"),
    formatter=formatter.to_formatter(),
  )
  inspect(
    rendered,
    content="[\u{001b}[32mINFO\u{001b}[0m] \u{001b}[38;2;76;201;240;1mtag\u{001b}[0m",
  )
}

///|
test "config builtin style markup ignores custom tags" {
  let formatter = TextFormatterConfig::new(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Builtin,
    style_tags={ "brand": text_style(fg=Some("#4cc9f0"), bold=true) },
  )
  let rendered = format_text(
    Record::new(Level::Info, "<brand>custom</> <red>builtin</>"),
    formatter=formatter.to_formatter(),
  )
  inspect(rendered, content="<brand>custom</> \u{001b}[31mbuiltin\u{001b}[0m")
}

///|
test "config disabled style markup keeps raw tags" {
  let formatter = TextFormatterConfig::new(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Disabled,
    style_tags={ "accent": text_style(fg=Some("#4cc9f0"), bold=true) },
  )
  let rendered = format_text(
    Record::new(Level::Info, "<accent>raw</> <red>tag</>"),
    formatter=formatter.to_formatter(),
  )
  inspect(rendered, content="<accent>raw</> <red>tag</>")
}

///|
test "config target and fields markup modes render separately" {
  let formatter = TextFormatterConfig::new(
    show_level=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Disabled,
    target_style_markup=StyleMarkupMode::Builtin,
    fields_style_markup=StyleMarkupMode::Builtin,
  )
  let rendered = format_text(
    Record::new(
      Level::Info,
      "<danger>message stays raw</>",
      target="<danger>svc</>",
      fields=[field("status", "<success>ok</>")],
    ),
    formatter=formatter.to_formatter(),
  )
  inspect(
    rendered,
    content="[\u{001b}[34m\u{001b}[31;1msvc\u{001b}[0m\u{001b}[0m] <danger>message stays raw</> \u{001b}[35mstatus=\u{001b}[32;1mok\u{001b}[0m\u{001b}[0m",
  )
}
