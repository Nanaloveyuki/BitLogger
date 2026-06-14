test "default logger can be reconfigured" {
  set_default_min_level(Level::Debug)
  set_default_target("global")
  let logger = default_logger()
  inspect(logger.min_level.label(), content="DEBUG")
  inspect(logger.target, content="global")
}

test "default logger snapshots shared defaults at creation time" {
  set_default_min_level(Level::Warn)
  set_default_target("before")
  let before = default_logger()

  set_default_min_level(Level::Debug)
  set_default_target("after")
  let after = default_logger()

  inspect(before.is_enabled(Level::Error), content="true")
  inspect(before.is_enabled(Level::Info), content="false")
  inspect(before.target, content="before")

  inspect(after.is_enabled(Level::Error), content="true")
  inspect(after.is_enabled(Level::Info), content="true")
  inspect(after.target, content="after")
}

test "logger can enable timestamps" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="time")
    .with_timestamp()
  inspect(logger.timestamp, content="true")
}

test "text formatter can customize visible parts" {
  let rec = record(
    Level::Info,
    "hello",
    timestamp_ms=123UL,
    target="svc.api",
    fields=[field("user", "alice"), field("request_id", "42")],
  )
  let compact = text_formatter(show_timestamp=false, show_target=false, field_separator=",")
  inspect(format_text(rec, formatter=compact), content="[INFO] hello user=alice,request_id=42")
}

test "text formatter can emit message only" {
  let rec = record(
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

test "text formatter supports template rendering" {
  let rec = record(
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
    format_text(rec, formatter=formatter),
    content="[INFO] svc.api template hello :: user=alice,request_id=42 @123",
  )
}

test "text formatter can render ansi level colors" {
  let rec = record(Level::Error, "boom", target="svc")
  let formatter = text_formatter(color_mode=ColorMode::Always)
  inspect(
    format_text(rec, formatter=formatter),
    content="[\u{001b}[31;1mERROR\u{001b}[0m] [\u{001b}[34msvc\u{001b}[0m] boom",
  )
}

test "text formatter auto color respects NO_COLOR" {
  let rec = record(Level::Warn, "boom", target="svc")
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

test "text formatter renders named inline color tags in ansi mode" {
  let rec = record(Level::Info, "<red>boom</>", target="svc")
  inspect(
    format_text(rec, formatter=text_formatter(color_mode=ColorMode::Always)),
    content="[\u{001b}[32mINFO\u{001b}[0m] [\u{001b}[34msvc\u{001b}[0m] \u{001b}[31mboom\u{001b}[0m",
  )
}

test "text formatter strips inline tags in plain mode" {
  let rec = record(Level::Info, "<red>boom</> <b>bold</>", target="svc")
  inspect(
    format_text(rec, formatter=text_formatter(color_mode=ColorMode::Never)),
    content="[INFO] [svc] boom bold",
  )
}

test "text formatter supports nested inline tags" {
  let rec = record(Level::Info, "<red><b>fatal</></>")
  inspect(
    format_text(rec, formatter=text_formatter(show_level=false, show_target=false, color_mode=ColorMode::Always)),
    content="\u{001b}[31;1mfatal\u{001b}[0m",
  )
}

test "text formatter supports named closing tags" {
  let rec = record(Level::Info, "<red>boom</red>")
  inspect(
    format_text(rec, formatter=text_formatter(show_level=false, show_target=false, color_mode=ColorMode::Always)),
    content="\u{001b}[31mboom\u{001b}[0m",
  )
}

test "text formatter supports mixed short and named closing tags" {
  let rec = record(Level::Info, "<red><b>fatal</b></red>")
  inspect(
    format_text(rec, formatter=text_formatter(show_level=false, show_target=false, color_mode=ColorMode::Always)),
    content="\u{001b}[31;1mfatal\u{001b}[0m",
  )
}

test "text formatter keeps unmatched named closing tags as plain text" {
  let rec = record(Level::Info, "boom</red>")
  inspect(
    format_text(rec, formatter=text_formatter(show_level=false, show_target=false)),
    content="boom</red>",
  )
}

test "text formatter supports hex inline colors" {
  let rec = record(Level::Info, "<#ff0000>hot</> <bg:#010203>bg</>")
  inspect(
    format_text(rec, formatter=text_formatter(show_level=false, show_target=false, color_mode=ColorMode::Always)),
    content="\u{001b}[38;2;255;0;0mhot\u{001b}[0m \u{001b}[48;2;1;2;3mbg\u{001b}[0m",
  )
}

test "text formatter can downgrade hex colors to basic ansi" {
  let rec = record(Level::Info, "<#ff0000>hot</> <bg:#010203>bg</>")
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

test "text formatter keeps unknown inline tags as plain text" {
  let rec = record(Level::Info, "<unknown>boom</>")
  inspect(
    format_text(rec, formatter=text_formatter(show_level=false, show_target=false)),
    content="<unknown>boom</>",
  )
}

test "text formatter can disable style markup parsing" {
  let rec = record(Level::Info, "<red>boom</> <b>bold</>", target="svc")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(color_mode=ColorMode::Always).without_style_markup(),
    ),
    content="[\u{001b}[32mINFO\u{001b}[0m] [\u{001b}[34msvc\u{001b}[0m] <red>boom</> <b>bold</>",
  )
}

test "text formatter builtin style markup mode ignores custom tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Builtin,
  ).with_style_tags(
    style_tag_registry().set_tag("brand", fg=Some("#4cc9f0"), bold=true),
  )
  let rec = record(Level::Info, "<brand>custom</> <red>builtin</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="<brand>custom</> \u{001b}[31mbuiltin\u{001b}[0m",
  )
}

test "style markup mode label is stable" {
  inspect(style_markup_mode_label(StyleMarkupMode::Disabled), content="disabled")
  inspect(style_markup_mode_label(StyleMarkupMode::Builtin), content="builtin")
  inspect(style_markup_mode_label(StyleMarkupMode::Full), content="full")
}

test "text formatter supports custom style tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    style_tag_registry().set_tag("accent", fg=Some("#4cc9f0"), bold=true),
  )
  let rec = record(Level::Info, "<accent>api</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="\u{001b}[38;2;76;201;240;1mapi\u{001b}[0m",
  )
}

test "text formatter can override builtin style tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    default_style_tag_registry().set_tag("red", fg=Some("#ff5a5f"), underline=true),
  )
  let rec = record(Level::Info, "<red>alert</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="\u{001b}[38;2;255;90;95;4malert\u{001b}[0m",
  )
}

test "formatter style tags take priority over global style tags" {
  let previous = global_style_tag_registry()
  set_global_style_tag_registry(style_tag_registry().set_tag("accent", fg=Some("#123456")))
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    style_tag_registry().set_tag("accent", fg=Some("#abcdef")),
  )
  let rec = record(Level::Info, "<accent>tag</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="\u{001b}[38;2;171;205;239mtag\u{001b}[0m",
  )
  set_global_style_tag_registry(previous)
}

test "global style tags apply when formatter has no local registry" {
  let previous = global_style_tag_registry()
  set_global_style_tag_registry(style_tag_registry().set_tag("accent", fg=Some("#102030"), dim=true))
  let rec = record(Level::Info, "<accent>tag</>")
  inspect(
    format_text(rec, formatter=text_formatter(show_level=false, show_target=false, color_mode=ColorMode::Always)),
    content="\u{001b}[38;2;16;32;48;2mtag\u{001b}[0m",
  )
  set_global_style_tag_registry(previous)
}

test "reset global style tag registry restores builtin defaults" {
  set_global_style_tag_registry(style_tag_registry().set_tag("accent", fg=Some("#123456"), bold=true))
  reset_global_style_tag_registry()
  let rec = record(Level::Info, "<success>ok</>")
  inspect(
    format_text(
      rec,
      formatter=text_formatter(show_level=false, show_target=false, color_mode=ColorMode::Always),
    ),
    content="\u{001b}[32;1mok\u{001b}[0m",
  )
}

test "style tag alias can reuse builtin tags" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    style_tag_registry().define_alias("danger", "red"),
  )
  let rec = record(Level::Info, "<danger>boom</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="\u{001b}[31mboom\u{001b}[0m",
  )
}

test "builtin semantic style tags are available" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Builtin,
  )
  let rec = record(Level::Info, "<success>ok</> <warning>careful</> <danger>boom</> <muted>quiet</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="\u{001b}[32;1mok\u{001b}[0m \u{001b}[33;1mcareful\u{001b}[0m \u{001b}[31;1mboom\u{001b}[0m \u{001b}[90;2mquiet\u{001b}[0m",
  )
}

test "builtin semantic style tags can still be overridden" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    default_style_tag_registry().set_tag("success", fg=Some("#00ffaa"), underline=true),
  )
  let rec = record(Level::Info, "<success>ok</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="\u{001b}[38;2;0;255;170;4mok\u{001b}[0m",
  )
}

test "text formatter can enable markup for target separately" {
  let formatter = text_formatter(
    show_level=false,
    color_mode=ColorMode::Always,
    target_style_markup=StyleMarkupMode::Builtin,
  )
  let rec = record(Level::Info, "hello", target="<danger>svc</>")
  inspect(
    format_text(rec, formatter=formatter),
    content="[\u{001b}[34m\u{001b}[31;1msvc\u{001b}[0m\u{001b}[0m] hello",
  )
}

test "text formatter can enable markup for field values separately" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    fields_style_markup=StyleMarkupMode::Builtin,
  )
  let rec = record(Level::Info, "hello", fields=[field("status", "<success>ok</>")])
  inspect(
    format_text(rec, formatter=formatter),
    content="hello \u{001b}[35mstatus=\u{001b}[32;1mok\u{001b}[0m\u{001b}[0m",
  )
}

test "text formatter leaves field keys raw when field markup is enabled" {
  let formatter = text_formatter(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    fields_style_markup=StyleMarkupMode::Builtin,
  )
  let rec = record(Level::Info, "hello", fields=[field("<danger>status</>", "ok")])
  inspect(
    format_text(rec, formatter=formatter),
    content="hello \u{001b}[35m<danger>status</>=ok\u{001b}[0m",
  )
}

test "text formatter template respects disabled fields" {
  let rec = record(Level::Warn, "just message", target="svc")
  let formatter = text_formatter(
    show_target=false,
    show_fields=false,
    template="[{level}] {target}{message}{fields}",
  )
  inspect(format_text(rec, formatter=formatter), content="[WARN] just message")
}

test "formatted callback sink receives rendered text" {
  let rendered : Ref[String] = Ref("")
  let sink = text_callback_sink(
    text_formatter(show_timestamp=false, separator=" | "),
    fn(text) {
      rendered.val = text
    },
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="svc")
  logger.info("hello", fields=[field("user", "alice")])
  inspect(rendered.val, content="[INFO] | [svc] | hello | user=alice")
}

test "native file support flag is queryable" {
  inspect(native_files_supported() == true || native_files_supported() == false, content="true")
}

test "file sink availability reflects backend support" {
  let sink = file_sink("bitlogger-test.log")
  let state = sink.state()
  inspect(sink.path(), content="bitlogger-test.log")
  inspect(sink.is_available() == native_files_supported(), content="true")
  inspect(state.path, content="bitlogger-test.log")
  inspect(state.available == sink.is_available(), content="true")
  inspect(state.append == sink.append_mode(), content="true")
  inspect(state.auto_flush == sink.auto_flush_enabled(), content="true")
  inspect((state.rotation is None) == (sink.rotation_config() is None), content="true")
  inspect(sink.append_mode(), content="true")
  inspect(sink.auto_flush_enabled(), content="true")
  inspect(sink.rotation_enabled(), content="false")
  inspect(sink.rotation_config() is None, content="true")
  inspect(sink.open_failures(), content=if sink.is_available() { "0" } else { "1" })
  inspect(sink.write_failures(), content="0")
  inspect(sink.flush_failures(), content="0")
  if sink.is_available() {
    inspect(sink.flush(), content="true")
    inspect(sink.close(), content="true")
  } else {
    inspect(sink.flush(), content="false")
    inspect(sink.close(), content="false")
  }
}

test "file sink unavailable backend keeps stable fallback state" {
  let sink = file_sink("bitlogger-unavailable.log", rotation=Some(file_rotation(64, max_backups=2)))
  if sink.is_available() {
    inspect(sink.state().available, content="true")
    ignore(sink.close())
  } else {
    let state = sink.state()
    inspect(native_files_supported(), content="false")
    inspect(state.available, content="false")
    inspect(sink.flush(), content="false")
    inspect(sink.close(), content="false")
    inspect(sink.write_failures(), content="0")
    sink.write(record(Level::Info, "dropped"))
    inspect(sink.write_failures(), content="1")
    inspect(sink.rotation_failures(), content="0")
    match state.rotation {
      Some(rotation) => {
        inspect(rotation.max_bytes, content="64")
        inspect(rotation.max_backups, content="2")
      }
      None => inspect(false, content="true")
    }
  }
}

test "file sink rotation config normalizes invalid inputs" {
  let rotation = file_rotation(0, max_backups=0)
  inspect(rotation.max_bytes, content="1")
  inspect(rotation.max_backups, content="1")
  let sink = file_sink("bitlogger-rotation-config.log", rotation=Some(rotation))
  inspect(sink.rotation_enabled(), content="true")
  match sink.rotation_config() {
    Some(config) => {
      inspect(config.max_bytes, content="1")
      inspect(config.max_backups, content="1")
    }
    None => inspect(false, content="true")
  }
}

test "file sink setters update auto flush and rotation state" {
  let sink = file_sink("bitlogger-setters.log")
  let default_policy = sink.default_policy()
  inspect(sink.append_mode(), content="true")
  inspect(sink.auto_flush_enabled(), content="true")
  inspect(sink.rotation_enabled(), content="false")
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(sink.policy_matches_default(), content="true")
  sink.set_append_mode(false)
  inspect(sink.append_mode(), content="false")
  sink.set_auto_flush(false)
  inspect(sink.auto_flush_enabled(), content="false")
  sink.set_rotation(Some(file_rotation(32, max_backups=2)))
  inspect(sink.rotation_enabled(), content="true")
  match sink.rotation_config() {
    Some(config) => {
      inspect(config.max_bytes, content="32")
      inspect(config.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  sink.clear_rotation()
  inspect(sink.rotation_enabled(), content="false")
  inspect(sink.rotation_config() is None, content="true")
  inspect(sink.reopen(), content=if sink.is_available() { "true" } else { "false" })
  inspect(sink.append_mode(), content="false")
  let state = sink.state()
  let policy = sink.policy()
  inspect(state.append, content="false")
  inspect(state.auto_flush, content="false")
  inspect(state.rotation is None, content="true")
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  inspect(policy.rotation is None, content="true")
  inspect(sink.policy_matches_default(), content="false")
  sink.reset_policy()
  inspect(sink.append_mode(), content="true")
  inspect(sink.auto_flush_enabled(), content="true")
  inspect(sink.rotation_config() is None, content="true")
  inspect(sink.policy_matches_default(), content="true")
}

test "file sink reset policy restores configured defaults" {
  let sink = file_sink(
    "bitlogger-reset-policy.log",
    append=false,
    auto_flush=false,
    rotation=Some(file_rotation(24, max_backups=3)),
  )
  sink.set_append_mode(true)
  sink.set_auto_flush(true)
  sink.clear_rotation()
  let default_policy = sink.default_policy()
  inspect(default_policy.append, content="false")
  inspect(default_policy.auto_flush, content="false")
  inspect(sink.policy_matches_default(), content="false")
  sink.reset_policy()
  inspect(sink.append_mode(), content="false")
  inspect(sink.auto_flush_enabled(), content="false")
  inspect(sink.policy_matches_default(), content="true")
  match sink.rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="24")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
}

test "file sink set policy applies bundled runtime policy" {
  let sink = file_sink("bitlogger-set-policy.log")
  let default_policy = sink.default_policy()
  sink.set_policy(
    FileSinkPolicy::new(
      append=false,
      auto_flush=false,
      rotation=Some(file_rotation(18, max_backups=2)),
    ),
  )
  let policy = sink.policy()
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  match policy.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="18")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(sink.policy_matches_default(), content="false")
}

test "file sink tracks rotation failures on unavailable backend" {
  let sink = file_sink("bitlogger-rotate.log", rotation=Some(file_rotation(1, max_backups=1)))
  sink.write(record(Level::Info, "a"))
  if sink.is_available() {
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.write_failures(), content="0")
    ignore(sink.close())
  } else {
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.write_failures(), content="1")
  }
}

test "file sink reopen and failure counters reflect backend state" {
  let sink = file_sink("bitlogger-reopen.log")
  if sink.is_available() {
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="0")
    inspect(sink.close(), content="true")
    inspect(sink.reopen_append(), content="true")
    inspect(sink.is_available(), content="true")
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="0")
    sink.write(record(Level::Info, "reopened"))
    inspect(sink.write_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.reopen_truncate(), content="true")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen(), content="true")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen_with_current_policy(), content="true")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen_append(), content="true")
    inspect(sink.append_mode(), content="true")
    sink.reset_failure_counters()
    inspect(sink.open_failures(), content="0")
    inspect(sink.write_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.close(), content="true")
    ignore(remove_file_internal("bitlogger-reopen.log"))
  } else {
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="1")
    sink.write(record(Level::Info, "dropped"))
    inspect(sink.write_failures(), content="1")
    inspect(sink.reopen_append(), content="false")
    inspect(sink.open_failures(), content="2")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.reopen_truncate(), content="false")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen_with_current_policy(), content="false")
    inspect(sink.open_failures(), content="4")
    inspect(sink.reopen_append(), content="false")
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="5")
    sink.reset_failure_counters()
    inspect(sink.open_failures(), content="0")
    inspect(sink.write_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.rotation_failures(), content="0")
  }
}

test "file sink can rotate on native backend" {
  let path = "bitlogger-rotate-native.log"
  ignore(remove_file_internal(path))
  ignore(remove_file_internal(path + ".1"))
  ignore(remove_file_internal(path + ".2"))
  let sink = file_sink(
    path,
    auto_flush=true,
    rotation=Some(file_rotation(20, max_backups=2)),
    formatter=fn(rec) { rec.message },
  )
  if sink.is_available() {
    sink.write(record(Level::Info, "1234567890"))
    sink.write(record(Level::Info, "abcdefghij"))
    let current = open_file_handle_internal(path, true)
    let rotated = open_file_handle_internal(path + ".1", true)
    inspect(current is Some(_), content="true")
    inspect(rotated is Some(_), content="true")
    match current {
      None => ()
      Some(handle) => ignore(close_file_handle_internal(handle))
    }
    match rotated {
      None => ()
      Some(handle) => ignore(close_file_handle_internal(handle))
    }
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.close(), content="true")
    ignore(remove_file_internal(path))
    ignore(remove_file_internal(path + ".1"))
    ignore(remove_file_internal(path + ".2"))
  } else {
    inspect(sink.rotation_failures(), content="0")
  }
}

test "json formatter keeps structured shape" {
  let rec = record(
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

test "callback sink receives record" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
    }),
    min_level=Level::Info,
    target="callback",
  )
  logger.info("hello")
  inspect(captured_target.val, content="callback")
  inspect(captured_message.val, content="hello")
}

test "split sink routes records by predicate" {
  let left_messages : Ref[Array[String]] = Ref([])
  let right_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    split_sink(
      callback_sink(fn(rec) {
        left_messages.val.push(rec.message)
      }),
      callback_sink(fn(rec) {
        right_messages.val.push(rec.message)
      }),
      fn(rec) {
        rec.target == "audit"
      },
    ),
    min_level=Level::Info,
    target="main",
  )
  logger.info("drop to right")
  logger.log(Level::Info, "keep on left", target="audit")
  inspect(left_messages.val.length(), content="1")
  inspect(left_messages.val[0], content="keep on left")
  inspect(right_messages.val.length(), content="1")
  inspect(right_messages.val[0], content="drop to right")
}

test "split_by_level routes warn and error separately" {
  let high_messages : Ref[Array[String]] = Ref([])
  let low_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    split_by_level(
      callback_sink(fn(rec) {
        high_messages.val.push(rec.level.label() + ":" + rec.message)
      }),
      callback_sink(fn(rec) {
        low_messages.val.push(rec.level.label() + ":" + rec.message)
      }),
      min_level=Level::Warn,
    ),
    min_level=Level::Trace,
    target="split",
  )
  logger.info("info")
  logger.warn("warn")
  logger.error("error")
  inspect(high_messages.val.length(), content="2")
  inspect(high_messages.val[0], content="WARN:warn")
  inspect(high_messages.val[1], content="ERROR:error")
  inspect(low_messages.val.length(), content="1")
  inspect(low_messages.val[0], content="INFO:info")
}

test "callback sink sees child target and context logger shape" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_field_count : Ref[Int] = Ref(0)
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_field_count.val = rec.fields.length()
      captured_timestamp.val = rec.timestamp_ms
    }),
    min_level=Level::Info,
    target="app",
  )
    .child("worker")
    .with_context_fields([field("service", "bitlogger")])
    .with_timestamp()
  logger.info("ready", fields=[field("mode", "test")])
  inspect(captured_target.val, content="app.worker")
  inspect(captured_message.val, content="ready")
  inspect(captured_field_count.val, content="2")
  inspect(captured_timestamp.val > 0UL, content="true")
}

test "bind aliases context fields ergonomically" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="bind",
  ).bind(fields([("service", "bitlogger"), ("scope", "audit")]))
  logger.info("ready", fields=[field("mode", "test")])
  inspect(captured_target.val, content="bind")
  inspect(captured_message.val, content="ready")
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="scope")
  inspect(captured_fields.val[1].value, content="audit")
  inspect(captured_fields.val[2].key, content="mode")
  inspect(captured_fields.val[2].value, content="test")
}

test "buffered sink flushes manually" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = buffered_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    flush_limit=10,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="buffered")
  logger.info("one")
  logger.info("two")
  inspect(sink.pending_count(), content="2")
  inspect(flushed_messages.val.length(), content="0")
  sink.flush()
  inspect(sink.pending_count(), content="0")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
}

test "buffered sink flushes automatically at limit" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = buffered_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    flush_limit=2,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="buffered")
  logger.info("one")
  inspect(sink.pending_count(), content="1")
  logger.info("two")
  inspect(sink.pending_count(), content="0")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
}

test "filter sink only forwards matching records" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = filter_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    fn(rec) {
      rec.target == "kept"
    },
  )
  let kept = Logger::new(sink, min_level=Level::Info, target="kept")
  let dropped = Logger::new(sink, min_level=Level::Info, target="dropped")
  kept.info("one")
  dropped.info("two")
  kept.info("three")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="three")
}

test "logger with_filter composes naturally" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Info,
    target="app",
  )
    .with_filter(fn(rec) {
      rec.target == "app.worker"
    })
  logger.info("drop at app")
  logger.child("worker").info("keep at worker")
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="keep at worker")
}

test "filter helpers support target level and message composition" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Trace,
    target="service",
  ).with_filter(all_of([
    target_has_prefix("service"),
    level_at_least(Level::Info),
    message_contains("visible"),
  ]))
  logger.debug("visible debug")
  logger.info("hidden info")
  logger.child("api").info("visible info")
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="visible info")
}

test "field helpers can match and negate records" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Info,
    target="fields",
  ).with_filter(all_of([
    has_field("request_id"),
    field_equals("kind", "audit"),
    not_(target_is("fields.drop")),
  ]))
  logger.info("missing field")
  logger.info("wrong kind", fields=[field("request_id", "1"), field("kind", "trace")])
  logger.child("drop").info("blocked target", fields=[field("request_id", "2"), field("kind", "audit")])
  logger.info("kept", fields=[field("request_id", "3"), field("kind", "audit")])
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="kept")
}

test "any_of helper accepts multiple predicates" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Info,
    target="multi",
  ).with_filter(any_of([
    target_is("multi.keep"),
    field_equals("force", "true"),
  ]))
  logger.info("drop")
  logger.child("keep").info("keep by target")
  logger.info("keep by field", fields=[field("force", "true")])
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="keep by target")
  inspect(flushed_messages.val[1], content="keep by field")
}

test "patch sink can rewrite message target and fields" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="auth",
  ).with_patch(compose_patches([
    set_target("audit.auth"),
    prefix_message("[safe] "),
    redact_field("token"),
    append_fields([field("service", "bitlogger")]),
  ]))
  logger.info("login", fields=[field("token", "secret"), field("user", "alice")])
  inspect(captured_target.val, content="audit.auth")
  inspect(captured_message.val, content="[safe] login")
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].key, content="token")
  inspect(captured_fields.val[0].value, content="***")
  inspect(captured_fields.val[1].key, content="user")
  inspect(captured_fields.val[1].value, content="alice")
  inspect(captured_fields.val[2].key, content="service")
  inspect(captured_fields.val[2].value, content="bitlogger")
}

test "patch helpers can redact multiple fields" {
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="audit",
  ).with_patch(redact_fields(["token", "password"], placeholder="[redacted]"))
  logger.info(
    "credentials",
    fields=[field("token", "abc"), field("password", "123"), field("user", "alice")],
  )
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].value, content="[redacted]")
  inspect(captured_fields.val[1].value, content="[redacted]")
  inspect(captured_fields.val[2].value, content="alice")
}

test "queued sink drains in order" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = queued_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="3")
  inspect(sink.dropped_count(), content="0")
  inspect(sink.drain(max_items=2), content="2")
  inspect(sink.pending_count(), content="1")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
  inspect(sink.flush(), content="1")
  inspect(sink.pending_count(), content="0")
  inspect(flushed_messages.val[2], content="three")
}

test "queued sink can drop newest when full" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = queued_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    max_pending=2,
    overflow=QueueOverflowPolicy::DropNewest,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  inspect(sink.flush(), content="2")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
}

test "queued sink can drop oldest when full" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = queued_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    max_pending=2,
    overflow=QueueOverflowPolicy::DropOldest,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  inspect(sink.flush(), content="2")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="two")
  inspect(flushed_messages.val[1], content="three")
}

test "logger with_queue preserves chaining ergonomics" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Info,
    target="service",
  )
    .with_patch(prefix_message("[queued] "))
    .with_queue(max_pending=2, overflow=QueueOverflowPolicy::DropOldest)
  logger.info("one")
  logger.child("api").info("two")
  logger.info("three")
  inspect(logger.sink.pending_count(), content="2")
  inspect(logger.sink.dropped_count(), content="1")
  inspect(logger.sink.flush(), content="2")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="[queued] two")
  inspect(flushed_messages.val[1], content="[queued] three")
}
