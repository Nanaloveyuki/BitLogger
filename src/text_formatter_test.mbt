///|
test "text formatter can customize visible parts" {
  let rec = Record::new(
    Level::Info,
    "hello",
    timestamp_ms=123UL,
    target="svc.api",
    fields=[field("user", "alice"), field("request_id", "42")],
  )
  let compact = text_formatter(
    show_timestamp=false,
    show_target=false,
    field_separator=",",
  )
  inspect(
    format_text(rec, formatter=compact),
    content="[INFO] hello user=alice,request_id=42",
  )
}

///|
test "text formatter can emit message only" {
  let rec = Record::new(
    Level::Warn,
    "just message",
    timestamp_ms=999UL,
    target="svc",
    fields=[field("ignored", "yes")],
  )
  let message_only = text_formatter(
    show_timestamp=false,
    show_level=false,
    show_target=false,
    show_fields=false,
  )
  inspect(format_text(rec, formatter=message_only), content="just message")
}

///|
test "text formatter supports template rendering" {
  let rec = Record::new(
    Level::Info,
    "template hello",
    timestamp_ms=123UL,
    target="svc.api",
    fields=[field("user", "alice"), field("request_id", "42")],
  )
  let formatter = text_formatter(
    separator=" | ",
    field_separator=",",
    template="[{level}] {target} {message} :: {fields} @{timestamp}",
  )
  inspect(
    format_text(rec, formatter~),
    content="[INFO] svc.api template hello :: user=alice,request_id=42 @123",
  )
}

///|
test "text formatter can render ansi level colors" {
  let rec = Record::new(Level::Error, "boom", target="svc")
  let formatter = text_formatter(color_mode=ColorMode::Always)
  inspect(
    format_text(rec, formatter~),
    content="[\u{001b}[31;1mERROR\u{001b}[0m] [\u{001b}[34msvc\u{001b}[0m] boom",
  )
}

///|
test "text formatter auto color respects NO_COLOR" {
  let rec = Record::new(Level::Warn, "boom", target="svc")
  let previous = @env.get_env_var("NO_COLOR")
  @env.set_env_var("NO_COLOR", "1")
  inspect(
    format_text(rec, formatter=text_formatter(color_mode=ColorMode::Auto)),
    content="[WARN] [svc] boom",
  )
  match previous {
    Some(value) => @env.set_env_var("NO_COLOR", value)
    None => @env.unset_env_var("NO_COLOR")
  }
}

///|
test "text formatter renders named inline color tags in ansi mode" {
  let rec = Record::new(Level::Info, "<red>boom</>", target="svc")
  inspect(
    format_text(rec, formatter=text_formatter(color_mode=ColorMode::Always)),
    content="[\u{001b}[32mINFO\u{001b}[0m] [\u{001b}[34msvc\u{001b}[0m] \u{001b}[31mboom\u{001b}[0m",
  )
}

///|
test "text formatter strips inline tags in plain mode" {
  let rec = Record::new(Level::Info, "<red>boom</> <b>bold</>", target="svc")
  inspect(
    format_text(rec, formatter=text_formatter(color_mode=ColorMode::Never)),
    content="[INFO] [svc] boom bold",
  )
}

///|
test "text formatter supports nested inline tags" {
  let rec = Record::new(Level::Info, "<red><b>fatal</></>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(
        show_level=false,
        show_target=false,
        color_mode=ColorMode::Always,
      ),
    ),
    content="\u{001b}[31;1mfatal\u{001b}[0m",
  )
}

///|
test "text formatter supports named closing tags" {
  let rec = Record::new(Level::Info, "<red>boom</red>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(
        show_level=false,
        show_target=false,
        color_mode=ColorMode::Always,
      ),
    ),
    content="\u{001b}[31mboom\u{001b}[0m",
  )
}

///|
test "text formatter supports mixed short and named closing tags" {
  let rec = Record::new(Level::Info, "<red><b>fatal</b></red>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(
        show_level=false,
        show_target=false,
        color_mode=ColorMode::Always,
      ),
    ),
    content="\u{001b}[31;1mfatal\u{001b}[0m",
  )
}

///|
test "text formatter keeps unmatched named closing tags as plain text" {
  let rec = Record::new(Level::Info, "boom</red>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(show_level=false, show_target=false),
    ),
    content="boom</red>",
  )
}

///|
test "text formatter supports hex inline colors" {
  let rec = Record::new(Level::Info, "<#ff0000>hot</> <bg:#010203>bg</>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(
        show_level=false,
        show_target=false,
        color_mode=ColorMode::Always,
      ),
    ),
    content="\u{001b}[38;2;255;0;0mhot\u{001b}[0m \u{001b}[48;2;1;2;3mbg\u{001b}[0m",
  )
}

///|
test "text formatter can downgrade hex colors to basic ansi" {
  let rec = Record::new(Level::Info, "<#ff0000>hot</> <bg:#010203>bg</>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(
        show_level=false,
        show_target=false,
        color_mode=ColorMode::Always,
        color_support=ColorSupport::Basic,
      ),
    ),
    content="\u{001b}[31mhot\u{001b}[0m \u{001b}[100mbg\u{001b}[0m",
  )
}

///|
test "text formatter keeps unknown inline tags as plain text" {
  let rec = Record::new(Level::Info, "<unknown>boom</>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(show_level=false, show_target=false),
    ),
    content="<unknown>boom</>",
  )
}

///|
test "text formatter can disable style markup parsing" {
  let rec = Record::new(Level::Info, "<red>boom</> <b>bold</>", target="svc")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(color_mode=ColorMode::Always).without_style_markup(),
    ),
    content="[\u{001b}[32mINFO\u{001b}[0m] [\u{001b}[34msvc\u{001b}[0m] <red>boom</> <b>bold</>",
  )
}

///|
test "text formatter builtin style markup mode ignores custom tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Builtin,
  ).with_style_tags(
    style_tag_registry().set_tag("brand", fg=Some("#4cc9f0"), bold=true),
  )
  let rec = Record::new(Level::Info, "<brand>custom</> <red>builtin</>")
  inspect(
    format_text(rec, formatter~),
    content="<brand>custom</> \u{001b}[31mbuiltin\u{001b}[0m",
  )
}

///|
test "style markup mode label is stable" {
  inspect(
    style_markup_mode_label(StyleMarkupMode::Disabled),
    content="disabled",
  )
  inspect(style_markup_mode_label(StyleMarkupMode::Builtin), content="builtin")
  inspect(style_markup_mode_label(StyleMarkupMode::Full), content="full")
}

///|
test "text formatter supports custom style tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    style_tag_registry().set_tag("accent", fg=Some("#4cc9f0"), bold=true),
  )
  let rec = Record::new(Level::Info, "<accent>api</>")
  inspect(
    format_text(rec, formatter~),
    content="\u{001b}[38;2;76;201;240;1mapi\u{001b}[0m",
  )
}

///|
test "text formatter can override builtin style tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    default_style_tag_registry().set_tag(
      "red",
      fg=Some("#ff5a5f"),
      underline=true,
    ),
  )
  let rec = Record::new(Level::Info, "<red>alert</>")
  inspect(
    format_text(rec, formatter~),
    content="\u{001b}[38;2;255;90;95;4malert\u{001b}[0m",
  )
}

///|
test "formatter style tags take priority over global style tags" {
  let previous = global_style_tag_registry()
  set_global_style_tag_registry(
    style_tag_registry().set_tag("accent", fg=Some("#123456")),
  )
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(style_tag_registry().set_tag("accent", fg=Some("#abcdef")))
  let rec = Record::new(Level::Info, "<accent>tag</>")
  inspect(
    format_text(rec, formatter~),
    content="\u{001b}[38;2;171;205;239mtag\u{001b}[0m",
  )
  set_global_style_tag_registry(previous)
}

///|
test "global style tags apply when formatter has no local registry" {
  let previous = global_style_tag_registry()
  set_global_style_tag_registry(
    style_tag_registry().set_tag("accent", fg=Some("#102030"), dim=true),
  )
  let rec = Record::new(Level::Info, "<accent>tag</>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(
        show_level=false,
        show_target=false,
        color_mode=ColorMode::Always,
      ),
    ),
    content="\u{001b}[38;2;16;32;48;2mtag\u{001b}[0m",
  )
  set_global_style_tag_registry(previous)
}

///|
test "reset global style tag registry restores builtin defaults" {
  set_global_style_tag_registry(
    style_tag_registry().set_tag("accent", fg=Some("#123456"), bold=true),
  )
  reset_global_style_tag_registry()
  let rec = Record::new(Level::Info, "<success>ok</>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(
        show_level=false,
        show_target=false,
        color_mode=ColorMode::Always,
      ),
    ),
    content="\u{001b}[32;1mok\u{001b}[0m",
  )
}

///|
test "style tag alias can reuse builtin tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(style_tag_registry().define_alias("danger", "red"))
  let rec = Record::new(Level::Info, "<danger>boom</>")
  inspect(format_text(rec, formatter~), content="\u{001b}[31mboom\u{001b}[0m")
}

///|
test "builtin semantic style tags are available" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Builtin,
  )
  let rec = Record::new(
    Level::Info,
    "<success>ok</> <warning>careful</> <danger>boom</> <muted>quiet</>",
  )
  inspect(
    format_text(rec, formatter~),
    content="\u{001b}[32;1mok\u{001b}[0m \u{001b}[33;1mcareful\u{001b}[0m \u{001b}[31;1mboom\u{001b}[0m \u{001b}[90;2mquiet\u{001b}[0m",
  )
}

///|
test "builtin semantic style tags can still be overridden" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    default_style_tag_registry().set_tag(
      "success",
      fg=Some("#00ffaa"),
      underline=true,
    ),
  )
  let rec = Record::new(Level::Info, "<success>ok</>")
  inspect(
    format_text(rec, formatter~),
    content="\u{001b}[38;2;0;255;170;4mok\u{001b}[0m",
  )
}

///|
test "text formatter can enable markup for target separately" {
  let formatter = text_formatter(
    show_level=false,
    color_mode=ColorMode::Always,
    target_style_markup=StyleMarkupMode::Builtin,
  )
  let rec = Record::new(Level::Info, "hello", target="<danger>svc</>")
  inspect(
    format_text(rec, formatter~),
    content="[\u{001b}[34m\u{001b}[31;1msvc\u{001b}[0m\u{001b}[0m] hello",
  )
}

///|
test "text formatter can enable markup for field values separately" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    fields_style_markup=StyleMarkupMode::Builtin,
  )
  let rec = Record::new(Level::Info, "hello", fields=[
    field("status", "<success>ok</>"),
  ])
  inspect(
    format_text(rec, formatter~),
    content="hello \u{001b}[35mstatus=\u{001b}[32;1mok\u{001b}[0m\u{001b}[0m",
  )
}

///|
test "text formatter leaves field keys raw when field markup is enabled" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    fields_style_markup=StyleMarkupMode::Builtin,
  )
  let rec = Record::new(Level::Info, "hello", fields=[
    field("<danger>status</>", "ok"),
  ])
  inspect(
    format_text(rec, formatter~),
    content="hello \u{001b}[35m<danger>status</>=ok\u{001b}[0m",
  )
}

///|
test "text formatter template respects disabled fields" {
  let rec = Record::new(Level::Warn, "just message", target="svc")
  let formatter = text_formatter(
    show_target=false,
    show_fields=false,
    template="[{level}] {target}{message}{fields}",
  )
  inspect(format_text(rec, formatter~), content="[WARN] just message")
}

///|
test "formatted callback sink receives rendered text" {
  let rendered : Ref[String] = Ref("")
  let sink = text_callback_sink(
    text_formatter(show_timestamp=false, separator=" | "),
    fn(text) { rendered.val = text },
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="svc")
  logger.info("hello", fields=[field("user", "alice")])
  inspect(rendered.val, content="[INFO] | [svc] | hello | user=alice")
}

///|
test "json formatter keeps structured shape" {
  let rec = Record::new(
    Level::Error,
    "failed",
    timestamp_ms=55UL,
    target="svc",
    fields=[field("code", "500")],
  )
  inspect(
    format_json(rec),
    content="{\"level\":\"ERROR\",\"message\":\"failed\",\"fields\":{\"code\":\"500\"},\"timestamp_ms\":\"55\",\"target\":\"svc\"}",
  )
}
