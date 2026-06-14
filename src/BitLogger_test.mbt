test "level filter works" {
  let logger = Logger::new(console_sink(), min_level=Level::Warn, target="test")
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
}

test "context sink merges fields" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="ctx")
    .with_context_fields([field("service", "bitlogger")])
  let merged = [field("service", "bitlogger"), field("mode", "test")]
  inspect(merged.length(), content="2")
  inspect(merged[0].key, content="service")
  inspect(merged[1].key, content="mode")
  logger.info("hello", fields=[field("mode", "test")])
}

test "fields helper builds field arrays ergonomically" {
  let items = fields([("service", "bitlogger"), ("mode", "test")])
  inspect(items.length(), content="2")
  inspect(items[0].key, content="service")
  inspect(items[0].value, content="bitlogger")
  inspect(items[1].key, content="mode")
  inspect(items[1].value, content="test")
}

test "fanout sink can write to plain and json outputs" {
  let logger = Logger::new(
    fanout_sink(console_sink(), json_console_sink()),
    min_level=Level::Info,
    target="fanout",
  )
  inspect(logger.is_enabled(Level::Info), content="true")
  logger.info("hello", fields=[field("kind", "dual")])
}

test "child logger composes target path" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="app")
    .child("worker")
  inspect(logger.target, content="app.worker")
}

test "logger config parser reads core options" {
  let config = parse_logger_config_text(
    "{\"min_level\":\"debug\",\"target\":\"service\",\"timestamp\":true}",
  )
  inspect(config.min_level.label(), content="DEBUG")
  inspect(config.target, content="service")
  inspect(config.timestamp, content="true")
}

test "logger config parser reads formatter and queue options" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"separator\":\" | \",\"show_timestamp\":false,\"template\":\"[{level}] {message}\",\"color_mode\":\"always\"}},\"queue\":{\"max_pending\":32,\"overflow\":\"DropOldest\"}}",
  )
  inspect(match config.sink.kind {
    SinkKind::TextConsole => "TextConsole"
    _ => "other"
  }, content="TextConsole")
  inspect(config.sink.text_formatter.separator, content=" | ")
  inspect(config.sink.text_formatter.show_timestamp, content="false")
  inspect(config.sink.text_formatter.template, content="[{level}] {message}")
  inspect(color_mode_label(config.sink.text_formatter.color_mode), content="always")
  match config.queue {
    Some(queue) => {
      inspect(queue.max_pending, content="32")
      inspect(match queue.overflow {
        QueueOverflowPolicy::DropNewest => "DropNewest"
        QueueOverflowPolicy::DropOldest => "DropOldest"
      }, content="DropOldest")
    }
    None => inspect(false, content="true")
  }
}

test "logger config parser reads formatter style tags" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"color_mode\":\"always\",\"color_support\":\"basic\",\"style_markup\":\"builtin\",\"target_style_markup\":\"builtin\",\"fields_style_markup\":\"disabled\",\"style_tags\":{\"accent\":{\"fg\":\"#4cc9f0\",\"bold\":true},\"panel\":{\"bg\":\"#202020\",\"underline\":true}}}}}",
  )
  inspect(style_markup_mode_label(config.sink.text_formatter.style_markup), content="builtin")
  inspect(color_support_label(config.sink.text_formatter.color_support), content="basic")
  inspect(style_markup_mode_label(config.sink.text_formatter.target_style_markup), content="builtin")
  inspect(style_markup_mode_label(config.sink.text_formatter.fields_style_markup), content="disabled")
  inspect(config.sink.text_formatter.style_tags.length(), content="2")
  match config.sink.text_formatter.style_tags.get("accent") {
    Some(style) => {
      inspect(style.fg.unwrap(), content="#4cc9f0")
      inspect(style.bold, content="true")
      inspect(style.bg is None, content="true")
    }
    None => inspect(false, content="true")
  }
  match config.sink.text_formatter.style_tags.get("panel") {
    Some(style) => {
      inspect(style.bg.unwrap(), content="#202020")
      inspect(style.underline, content="true")
    }
    None => inspect(false, content="true")
  }
}

test "logger config parser reads file rotation options" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"file\",\"path\":\"bitlogger.log\",\"rotation\":{\"max_bytes\":128,\"max_backups\":3}}}",
  )
  inspect(match config.sink.kind {
    SinkKind::File => "File"
    _ => "other"
  }, content="File")
  inspect(config.sink.path, content="bitlogger.log")
  match config.sink.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="128")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
}

test "logger config parser fills omitted top-level keys from defaults" {
  let config = parse_logger_config_text("{}")
  inspect(config.min_level.label(), content="INFO")
  inspect(config.target, content="")
  inspect(config.timestamp, content="false")
  inspect(config.queue is None, content="true")
  inspect(match config.sink.kind {
    SinkKind::Console => "Console"
    SinkKind::JsonConsole => "JsonConsole"
    SinkKind::TextConsole => "TextConsole"
    SinkKind::File => "File"
  }, content="Console")
  inspect(config.sink.path, content="")
  inspect(config.sink.append, content="true")
  inspect(config.sink.auto_flush, content="true")
  inspect(config.sink.rotation is None, content="true")
  inspect(config.sink.text_formatter.show_timestamp, content="true")
  inspect(config.sink.text_formatter.separator, content=" ")
  inspect(config.sink.text_formatter.field_separator, content=" ")
  inspect(config.sink.text_formatter.template, content="")
}

test "logger config parser fills nested queue and formatter defaults" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"separator\":\" | \"}},\"queue\":{\"max_pending\":4}}",
  )
  inspect(match config.sink.kind {
    SinkKind::Console => "Console"
    SinkKind::JsonConsole => "JsonConsole"
    SinkKind::TextConsole => "TextConsole"
    SinkKind::File => "File"
  }, content="TextConsole")
  inspect(config.sink.text_formatter.show_timestamp, content="true")
  inspect(config.sink.text_formatter.show_level, content="true")
  inspect(config.sink.text_formatter.show_target, content="true")
  inspect(config.sink.text_formatter.show_fields, content="true")
  inspect(config.sink.text_formatter.separator, content=" | ")
  inspect(config.sink.text_formatter.field_separator, content=" ")
  inspect(config.sink.text_formatter.template, content="")
  inspect(color_mode_label(config.sink.text_formatter.color_mode), content="never")
  inspect(color_support_label(config.sink.text_formatter.color_support), content="truecolor")
  inspect(style_markup_mode_label(config.sink.text_formatter.style_markup), content="full")
  inspect(style_markup_mode_label(config.sink.text_formatter.target_style_markup), content="disabled")
  inspect(style_markup_mode_label(config.sink.text_formatter.fields_style_markup), content="disabled")
  inspect(config.sink.text_formatter.style_tags.length(), content="0")
  match config.queue {
    Some(queue) => {
      inspect(queue.max_pending, content="4")
      inspect(match queue.overflow {
        QueueOverflowPolicy::DropNewest => "DropNewest"
        QueueOverflowPolicy::DropOldest => "DropOldest"
      }, content="DropNewest")
    }
    None => inspect(false, content="true")
  }
}

test "logger config parser rejects malformed sync config input" {
  let invalid_json_error = (fn() -> String raise ConfigError {
    ignore(parse_logger_config_text("{"))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(invalid_json_error.contains("Invalid JSON:"), content="true")

  let wrong_type_error = (fn() -> String raise ConfigError {
    ignore(parse_logger_config_text("{\"timestamp\":\"true\"}"))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(wrong_type_error, content="Expected bool at key timestamp")

  let invalid_enum_error = (fn() -> String raise ConfigError {
    ignore(parse_logger_config_text("{\"sink\":{\"kind\":\"console\",\"text_formatter\":{\"color_mode\":\"loud\"}}}"))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(invalid_enum_error, content="Unsupported color mode: loud")
}

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
  inspect(config.sink.text_formatter.template, content="[{level}] {target} {message}")
}

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
  inspect(color_mode_label(config.sink.text_formatter.color_mode), content="always")
  inspect(color_support_label(config.sink.text_formatter.color_support), content="basic")
  inspect(style_markup_mode_label(config.sink.text_formatter.style_markup), content="builtin")
  inspect(style_markup_mode_label(config.sink.text_formatter.target_style_markup), content="builtin")
  inspect(style_markup_mode_label(config.sink.text_formatter.fields_style_markup), content="disabled")
  inspect(config.sink.text_formatter.style_tags.length(), content="2")
  inspect(config.sink.text_formatter.style_tags.get("accent").unwrap().fg.unwrap(), content="#4cc9f0")
  inspect(config.sink.text_formatter.style_tags.get("accent").unwrap().bold, content="true")
  inspect(config.sink.text_formatter.style_tags.get("panel").unwrap().bg.unwrap(), content="#202020")
  inspect(config.sink.text_formatter.style_tags.get("panel").unwrap().dim, content="true")
}

test "logger config stringify roundtrips file rotation fields" {
  let text = stringify_logger_config(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="bitlogger.log",
        rotation=Some(file_rotation(256, max_backups=2)),
      ),
    ),
  )
  let config = parse_logger_config_text(text)
  inspect(config.sink.path, content="bitlogger.log")
  match config.sink.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="256")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
}

test "config subtype json helpers stringify stable shapes" {
  inspect(
    stringify_queue_config(
      QueueConfig::new(8, overflow=QueueOverflowPolicy::DropOldest),
    ),
    content="{\"max_pending\":8,\"overflow\":\"DropOldest\"}",
  )
  inspect(
    stringify_text_formatter_config(
      TextFormatterConfig::new(
        show_timestamp=false,
        show_level=true,
        show_target=false,
        show_fields=true,
        separator=" | ",
        field_separator=",",
        template="[{level}] {message} :: {fields}",
        color_mode=ColorMode::Always,
        color_support=ColorSupport::Basic,
        style_markup=StyleMarkupMode::Builtin,
        target_style_markup=StyleMarkupMode::Builtin,
        fields_style_markup=StyleMarkupMode::Disabled,
        style_tags={
          "accent": text_style(fg=Some("#4cc9f0"), bold=true),
        },
      ),
    ),
    content="{\"show_timestamp\":false,\"show_level\":true,\"show_target\":false,\"show_fields\":true,\"separator\":\" | \",\"field_separator\":\",\",\"template\":\"[{level}] {message} :: {fields}\",\"color_mode\":\"always\",\"color_support\":\"basic\",\"style_markup\":\"builtin\",\"target_style_markup\":\"builtin\",\"fields_style_markup\":\"disabled\",\"style_tags\":{\"accent\":{\"bold\":true,\"dim\":false,\"italic\":false,\"underline\":false,\"fg\":\"#4cc9f0\"}}}",
  )
  inspect(
    stringify_sink_config(
      SinkConfig::new(
        kind=SinkKind::File,
        path="demo.log",
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(128, max_backups=2)),
        text_formatter=TextFormatterConfig::new(show_timestamp=false, color_mode=ColorMode::Auto),
      ),
    ),
    content="{\"kind\":\"file\",\"path\":\"demo.log\",\"append\":false,\"auto_flush\":false,\"text_formatter\":{\"show_timestamp\":false,\"show_level\":true,\"show_target\":true,\"show_fields\":true,\"separator\":\" \",\"field_separator\":\" \",\"template\":\"\",\"color_mode\":\"auto\",\"color_support\":\"truecolor\",\"style_markup\":\"full\",\"target_style_markup\":\"disabled\",\"fields_style_markup\":\"disabled\"},\"rotation\":{\"max_bytes\":128,\"max_backups\":2}}",
  )
}

test "config json helpers export stable structured shapes" {
  let queue_json = queue_config_to_json(
    QueueConfig::new(8, overflow=QueueOverflowPolicy::DropOldest),
  )
  let queue_obj = queue_json.as_object().unwrap()
  inspect(@json_parser.stringify(queue_json), content="{\"max_pending\":8,\"overflow\":\"DropOldest\"}")
  inspect(queue_obj.get("max_pending").unwrap().as_number().unwrap().to_int(), content="8")
  inspect(queue_obj.get("overflow").unwrap().as_string().unwrap(), content="DropOldest")

  let formatter_json = text_formatter_config_to_json(
    TextFormatterConfig::new(
      show_timestamp=false,
      show_level=true,
      show_target=false,
      show_fields=true,
      separator=" | ",
      field_separator=",",
      template="[{level}] {message} :: {fields}",
      color_mode=ColorMode::Always,
      color_support=ColorSupport::Basic,
      style_markup=StyleMarkupMode::Builtin,
      target_style_markup=StyleMarkupMode::Builtin,
      fields_style_markup=StyleMarkupMode::Disabled,
      style_tags={
        "accent": text_style(fg=Some("#4cc9f0"), bold=true),
      },
    ),
  )
  let formatter_obj = formatter_json.as_object().unwrap()
  let style_tags_obj = formatter_obj.get("style_tags").unwrap().as_object().unwrap()
  let accent_obj = style_tags_obj.get("accent").unwrap().as_object().unwrap()
  inspect(formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(), content="false")
  inspect(formatter_obj.get("show_target").unwrap().as_bool().unwrap(), content="false")
  inspect(formatter_obj.get("separator").unwrap().as_string().unwrap(), content=" | ")
  inspect(formatter_obj.get("field_separator").unwrap().as_string().unwrap(), content=",")
  inspect(formatter_obj.get("template").unwrap().as_string().unwrap(), content="[{level}] {message} :: {fields}")
  inspect(formatter_obj.get("color_mode").unwrap().as_string().unwrap(), content="always")
  inspect(formatter_obj.get("color_support").unwrap().as_string().unwrap(), content="basic")
  inspect(formatter_obj.get("style_markup").unwrap().as_string().unwrap(), content="builtin")
  inspect(formatter_obj.get("target_style_markup").unwrap().as_string().unwrap(), content="builtin")
  inspect(formatter_obj.get("fields_style_markup").unwrap().as_string().unwrap(), content="disabled")
  inspect(accent_obj.get("bold").unwrap().as_bool().unwrap(), content="true")
  inspect(accent_obj.get("fg").unwrap().as_string().unwrap(), content="#4cc9f0")

  let sink_json = sink_config_to_json(
    SinkConfig::new(
      kind=SinkKind::File,
      path="demo.log",
      append=false,
      auto_flush=false,
      rotation=Some(file_rotation(128, max_backups=2)),
      text_formatter=TextFormatterConfig::new(show_timestamp=false, color_mode=ColorMode::Auto),
    ),
  )
  let sink_obj = sink_json.as_object().unwrap()
  let sink_formatter_obj = sink_obj.get("text_formatter").unwrap().as_object().unwrap()
  let rotation_obj = sink_obj.get("rotation").unwrap().as_object().unwrap()
  inspect(sink_obj.get("kind").unwrap().as_string().unwrap(), content="file")
  inspect(sink_obj.get("path").unwrap().as_string().unwrap(), content="demo.log")
  inspect(sink_obj.get("append").unwrap().as_bool().unwrap(), content="false")
  inspect(sink_obj.get("auto_flush").unwrap().as_bool().unwrap(), content="false")
  inspect(sink_formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(), content="false")
  inspect(sink_formatter_obj.get("color_mode").unwrap().as_string().unwrap(), content="auto")
  inspect(rotation_obj.get("max_bytes").unwrap().as_number().unwrap().to_int(), content="128")
  inspect(rotation_obj.get("max_backups").unwrap().as_number().unwrap().to_int(), content="2")

  let logger_json = logger_config_to_json(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="api",
      timestamp=true,
      sink=SinkConfig::new(kind=SinkKind::TextConsole),
      queue=Some(QueueConfig::new(8, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let logger_obj = logger_json.as_object().unwrap()
  let logger_sink_obj = logger_obj.get("sink").unwrap().as_object().unwrap()
  let logger_queue_obj = logger_obj.get("queue").unwrap().as_object().unwrap()
  inspect(logger_obj.get("min_level").unwrap().as_string().unwrap(), content="WARN")
  inspect(logger_obj.get("target").unwrap().as_string().unwrap(), content="api")
  inspect(logger_obj.get("timestamp").unwrap().as_bool().unwrap(), content="true")
  inspect(logger_sink_obj.get("kind").unwrap().as_string().unwrap(), content="text_console")
  inspect(logger_queue_obj.get("max_pending").unwrap().as_number().unwrap().to_int(), content="8")
  inspect(logger_queue_obj.get("overflow").unwrap().as_string().unwrap(), content="DropNewest")
}

test "logger config json export materializes parsed omitted defaults" {
  let parsed = parse_logger_config_text("{}")
  let logger_json = logger_config_to_json(parsed)
  let logger_obj = logger_json.as_object().unwrap()
  let sink_obj = logger_obj.get("sink").unwrap().as_object().unwrap()
  let formatter_obj = sink_obj.get("text_formatter").unwrap().as_object().unwrap()

  inspect(
    @json_parser.stringify(logger_json),
    content="{\"min_level\":\"INFO\",\"target\":\"\",\"timestamp\":false,\"sink\":{\"kind\":\"console\",\"path\":\"\",\"append\":true,\"auto_flush\":true,\"text_formatter\":{\"show_timestamp\":true,\"show_level\":true,\"show_target\":true,\"show_fields\":true,\"separator\":\" \",\"field_separator\":\" \",\"template\":\"\",\"color_mode\":\"never\",\"color_support\":\"truecolor\",\"style_markup\":\"full\",\"target_style_markup\":\"disabled\",\"fields_style_markup\":\"disabled\"}}}",
  )
  inspect(logger_obj.get("min_level").unwrap().as_string().unwrap(), content="INFO")
  inspect(logger_obj.get("target").unwrap().as_string().unwrap(), content="")
  inspect(logger_obj.get("timestamp").unwrap().as_bool().unwrap(), content="false")
  inspect(logger_obj.get("queue") is None, content="true")
  inspect(sink_obj.get("kind").unwrap().as_string().unwrap(), content="console")
  inspect(sink_obj.get("path").unwrap().as_string().unwrap(), content="")
  inspect(sink_obj.get("append").unwrap().as_bool().unwrap(), content="true")
  inspect(sink_obj.get("auto_flush").unwrap().as_bool().unwrap(), content="true")
  inspect(formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(), content="true")
  inspect(formatter_obj.get("show_level").unwrap().as_bool().unwrap(), content="true")
  inspect(formatter_obj.get("show_target").unwrap().as_bool().unwrap(), content="true")
  inspect(formatter_obj.get("show_fields").unwrap().as_bool().unwrap(), content="true")
  inspect(formatter_obj.get("separator").unwrap().as_string().unwrap(), content=" ")
  inspect(formatter_obj.get("field_separator").unwrap().as_string().unwrap(), content=" ")
  inspect(formatter_obj.get("template").unwrap().as_string().unwrap(), content="")
  inspect(formatter_obj.get("color_mode").unwrap().as_string().unwrap(), content="never")
  inspect(formatter_obj.get("color_support").unwrap().as_string().unwrap(), content="truecolor")
  inspect(formatter_obj.get("style_markup").unwrap().as_string().unwrap(), content="full")
  inspect(formatter_obj.get("target_style_markup").unwrap().as_string().unwrap(), content="disabled")
  inspect(formatter_obj.get("fields_style_markup").unwrap().as_string().unwrap(), content="disabled")
  inspect(formatter_obj.get("style_tags") is None, content="true")
}

test "default config helpers expose baseline config shapes" {
  let formatter = default_text_formatter_config()
  inspect(formatter.show_timestamp, content="true")
  inspect(color_mode_label(formatter.color_mode), content="never")
  inspect(color_support_label(formatter.color_support), content="truecolor")
  inspect(style_markup_mode_label(formatter.style_markup), content="full")

  let sink = default_sink_config()
  inspect(match sink.kind {
    SinkKind::Console => "Console"
    _ => "other"
  }, content="Console")
  inspect(sink.path, content="")
  inspect(sink.rotation is None, content="true")

  let logger = default_logger_config()
  inspect(logger.min_level.label(), content="INFO")
  inspect(logger.target, content="")
  inspect(logger.timestamp, content="false")
  inspect(logger.queue is None, content="true")
  inspect(match logger.sink.kind {
    SinkKind::Console => "Console"
    _ => "other"
  }, content="Console")
}

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
  inspect(rendered, content="\u{001b}[31mhot\u{001b}[0m \u{001b}[100mbg\u{001b}[0m")
}

test "config formatter style tags render in built logger" {
  let formatter = TextFormatterConfig::new(
    show_timestamp=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_tags={
      "accent": text_style(fg=Some("#4cc9f0"), bold=true),
    },
  )
  let rendered = format_text(
    Record::new(Level::Info, "<accent>tag</>"),
    formatter=formatter.to_formatter(),
  )
  inspect(rendered, content="[\u{001b}[32mINFO\u{001b}[0m] \u{001b}[38;2;76;201;240;1mtag\u{001b}[0m")
}

test "config builtin style markup ignores custom tags" {
  let formatter = TextFormatterConfig::new(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Builtin,
    style_tags={
      "brand": text_style(fg=Some("#4cc9f0"), bold=true),
    },
  )
  let rendered = format_text(
    Record::new(Level::Info, "<brand>custom</> <red>builtin</>"),
    formatter=formatter.to_formatter(),
  )
  inspect(rendered, content="<brand>custom</> \u{001b}[31mbuiltin\u{001b}[0m")
}

test "config disabled style markup keeps raw tags" {
  let formatter = TextFormatterConfig::new(
    show_level=false,
    show_target=false,
    color_mode=ColorMode::Always,
    style_markup=StyleMarkupMode::Disabled,
    style_tags={
      "accent": text_style(fg=Some("#4cc9f0"), bold=true),
    },
  )
  let rendered = format_text(
    Record::new(Level::Info, "<accent>raw</> <red>tag</>"),
    formatter=formatter.to_formatter(),
  )
  inspect(rendered, content="<accent>raw</> <red>tag</>")
}

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

test "build logger from config supports queued text console" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Debug,
      target="config.runtime",
      timestamp=true,
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(show_timestamp=false, separator=" | "),
      ),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.flush(), content="2")
}

test "configured logger drain supports partial queue draining" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.partial",
      sink=SinkConfig::new(kind=SinkKind::Console),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(logger.pending_count(), content="3")
  inspect(logger.drain(max_items=2), content="2")
  inspect(logger.pending_count(), content="1")
  inspect(logger.flush(), content="1")
}

test "configured logger reports dropped_count for bounded queue" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.drop",
      sink=SinkConfig::new(kind=SinkKind::TextConsole),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  logger.info("three")
  logger.info("four")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="2")
  inspect(logger.flush(), content="2")
}

test "configured logger queue helpers stay aligned with runtime sink helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="config.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::TextConsole,
        text_formatter=TextFormatterConfig::new(show_timestamp=false, show_target=false),
      ),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  let sink = logger.sink

  logger.info("one")
  logger.info("two")
  logger.info("three")

  inspect(logger.pending_count() == sink.pending_count(), content="true")
  inspect(logger.dropped_count() == sink.dropped_count(), content="true")
  inspect(logger.drain(max_items=1) == sink.drain(max_items=1), content="true")
  inspect(logger.pending_count() == sink.pending_count(), content="true")
  inspect(logger.flush() == sink.flush(), content="true")
  inspect(logger.pending_count() == sink.pending_count(), content="true")
  inspect(logger.dropped_count() == sink.dropped_count(), content="true")
}

test "configured logger close stays aligned with runtime sink close" {
  let console_config = LoggerConfig::new(
    min_level=Level::Info,
    target="config.close.console",
    sink=SinkConfig::new(kind=SinkKind::Console),
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
  )
  let console_logger = build_logger(console_config)
  let console_sink = build_logger(console_config).sink
  inspect(console_logger.close() == console_sink.close(), content="true")

  let file_config = LoggerConfig::new(
    target="config.close.file",
    sink=SinkConfig::new(kind=SinkKind::File, path="config-close.log"),
  )
  let file_logger = build_logger(file_config)
  let file_sink = build_logger(file_config).sink
  inspect(file_logger.close() == file_sink.close(), content="true")
}

test "runtime sink queue helpers forward direct queue state" {
  let sink = RuntimeSink::QueuedTextConsole(
    queued_sink(
      text_console_sink(text_formatter(show_timestamp=false, show_target=false)),
      max_pending=2,
      overflow=QueueOverflowPolicy::DropOldest,
    ),
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="runtime.queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  inspect(sink.drain(max_items=1), content="1")
  inspect(sink.pending_count(), content="1")
  inspect(sink.flush(), content="1")
  inspect(sink.pending_count(), content="0")
}

test "runtime sink plain variants use documented fallback counts" {
  let console_sink = RuntimeSink::Console(console_sink())
  inspect(console_sink.pending_count(), content="0")
  inspect(console_sink.dropped_count(), content="0")
  inspect(console_sink.flush(), content="0")
  inspect(console_sink.drain(), content="0")

  let file_sink = RuntimeSink::File(file_sink("runtime-direct.log", auto_flush=false))
  inspect(file_sink.pending_count(), content="0")
  inspect(file_sink.dropped_count(), content="0")
  if file_sink.file_available() {
    inspect(file_sink.flush(), content="1")
    inspect(file_sink.drain(), content="1")
    inspect(file_sink.close(), content="true")
  } else {
    inspect(file_sink.flush(), content="0")
    inspect(file_sink.drain(), content="0")
    inspect(file_sink.close(), content="false")
  }
}

test "runtime sink non-file variants expose documented file fallbacks" {
  let sink = RuntimeSink::Console(console_sink())
  inspect(sink.file_available(), content="false")
  inspect(sink.file_path(), content="")
  inspect(sink.file_append_mode(), content="false")
  inspect(sink.file_auto_flush(), content="false")
  inspect(sink.file_rotation_enabled(), content="false")
  inspect(sink.file_rotation_config() is None, content="true")
  inspect(sink.file_open_failures(), content="0")
  inspect(sink.file_write_failures(), content="0")
  inspect(sink.file_flush_failures(), content="0")
  inspect(sink.file_rotation_failures(), content="0")
  inspect(sink.file_reopen(), content="false")
  inspect(sink.file_reopen_with_current_policy(), content="false")
  inspect(sink.file_reopen_append(), content="false")
  inspect(sink.file_reopen_truncate(), content="false")
  inspect(sink.file_set_append_mode(true), content="false")
  inspect(sink.file_set_auto_flush(true), content="false")
  inspect(sink.file_set_rotation(Some(file_rotation(32, max_backups=2))), content="false")
  inspect(sink.file_clear_rotation(), content="false")
  inspect(sink.file_set_policy(FileSinkPolicy::new()), content="false")
  inspect(sink.file_reset_failure_counters(), content="false")
  inspect(sink.file_reset_policy(), content="false")
  inspect(sink.file_flush(), content="false")
  inspect(sink.file_close(), content="false")
  let policy = sink.file_policy()
  let defaults = sink.file_default_policy()
  let state = sink.file_state()
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  inspect(policy.rotation is None, content="true")
  inspect(defaults.append, content="false")
  inspect(defaults.auto_flush, content="false")
  inspect(defaults.rotation is None, content="true")
  inspect(sink.file_policy_matches_default(), content="false")
  inspect(state.path, content="")
  inspect(state.available, content="false")
  inspect(state.append, content="false")
  inspect(state.auto_flush, content="false")
  inspect(state.rotation is None, content="true")
  inspect(state.open_failures, content="0")
  inspect(state.write_failures, content="0")
  inspect(state.flush_failures, content="0")
  inspect(state.rotation_failures, content="0")
  inspect(sink.file_runtime_state() is None, content="true")
}

test "runtime sink plain file helpers expose direct file state and policy" {
  let sink = RuntimeSink::File(
    file_sink(
      "runtime-file-helpers.log",
      auto_flush=false,
      rotation=Some(file_rotation(40, max_backups=2)),
    ),
  )
  inspect(sink.file_available() == native_files_supported(), content="true")
  inspect(sink.file_path(), content="runtime-file-helpers.log")
  inspect(sink.file_append_mode(), content="true")
  inspect(sink.file_auto_flush(), content="false")
  inspect(sink.file_rotation_enabled(), content="true")
  let defaults = sink.file_default_policy()
  let policy = sink.file_policy()
  inspect(defaults.append, content="true")
  inspect(defaults.auto_flush, content="false")
  inspect(policy.append, content="true")
  inspect(policy.auto_flush, content="false")
  inspect(sink.file_policy_matches_default(), content="true")
  match sink.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="40")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  let state = sink.file_state()
  inspect(state.path, content="runtime-file-helpers.log")
  inspect(state.available == sink.file_available(), content="true")
  inspect(state.append, content="true")
  inspect(state.auto_flush, content="false")
  match sink.file_runtime_state() {
    Some(snapshot) => {
      inspect(snapshot.queued, content="false")
      inspect(snapshot.pending_count, content="0")
      inspect(snapshot.dropped_count, content="0")
      inspect(snapshot.file.path, content="runtime-file-helpers.log")
    }
    None => inspect(false, content="true")
  }
  inspect(sink.file_set_append_mode(false), content="true")
  inspect(sink.file_set_auto_flush(true), content="true")
  inspect(sink.file_clear_rotation(), content="true")
  inspect(sink.file_policy_matches_default(), content="false")
  inspect(sink.file_append_mode(), content="false")
  inspect(sink.file_auto_flush(), content="true")
  inspect(sink.file_rotation_config() is None, content="true")
  inspect(sink.file_reset_policy(), content="true")
  inspect(sink.file_policy_matches_default(), content="true")
  inspect(sink.file_append_mode(), content="true")
  inspect(sink.file_auto_flush(), content="false")
  inspect(sink.file_rotation_enabled(), content="true")
  if sink.file_available() {
    inspect(sink.file_flush(), content="true")
    inspect(sink.file_close(), content="true")
  } else {
    inspect(sink.file_flush(), content="false")
    inspect(sink.file_close(), content="false")
  }
}

test "runtime sink queued file helpers preserve queue-aware file runtime state" {
  let sink = RuntimeSink::QueuedFile(
    queued_sink(
      file_sink("runtime-queued-file.log", auto_flush=false),
      max_pending=2,
      overflow=QueueOverflowPolicy::DropNewest,
    ),
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="runtime.file.queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.file_available() == native_files_supported(), content="true")
  inspect(sink.file_path(), content="runtime-queued-file.log")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  match sink.file_runtime_state() {
    Some(snapshot) => {
      inspect(snapshot.queued, content="true")
      inspect(snapshot.pending_count, content="2")
      inspect(snapshot.dropped_count, content="1")
      inspect(snapshot.file.path, content="runtime-queued-file.log")
    }
    None => inspect(false, content="true")
  }
  if sink.file_available() {
    inspect(sink.file_flush(), content="true")
    inspect(sink.pending_count(), content="0")
    match sink.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(sink.file_close(), content="true")
  } else {
    inspect(sink.file_flush(), content="false")
    inspect(sink.pending_count(), content="0")
    match sink.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(sink.file_close(), content="false")
  }
}

test "runtime sink plain file reopen helpers and failure resets work directly" {
  let sink = RuntimeSink::File(file_sink("runtime-reopen-direct.log"))
  if sink.file_available() {
    inspect(sink.close(), content="true")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_available(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="0")
    Logger::new(sink, min_level=Level::Info, target="runtime.reopen.direct").info("reopened")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_reopen_truncate(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
    inspect(sink.close(), content="true")
  } else {
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="1")
    Logger::new(sink, min_level=Level::Info, target="runtime.reopen.direct").info("dropped")
    inspect(sink.file_write_failures(), content="1")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_open_failures(), content="2")
    inspect(sink.file_reopen_truncate(), content="false")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="false")
    inspect(sink.file_open_failures(), content="4")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="5")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
  }
}

test "runtime sink queued file reopen helpers and failure resets work directly" {
  let sink = RuntimeSink::QueuedFile(
    queued_sink(file_sink("runtime-reopen-queued.log"), max_pending=2),
  )
  if sink.file_available() {
    inspect(sink.file_close(), content="true")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_available(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="0")
    let logger = Logger::new(sink, min_level=Level::Info, target="runtime.reopen.queued")
    logger.info("one")
    logger.info("two")
    inspect(sink.pending_count(), content="2")
    inspect(sink.file_reopen_truncate(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="true")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_append(), content="true")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
    inspect(sink.file_close(), content="true")
  } else {
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="1")
    let logger = Logger::new(sink, min_level=Level::Info, target="runtime.reopen.queued")
    logger.info("one")
    inspect(sink.pending_count(), content="1")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush(), content="false")
    inspect(sink.pending_count(), content="0")
    inspect(sink.file_write_failures(), content="1")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_open_failures(), content="2")
    inspect(sink.file_reopen_truncate(), content="false")
    inspect(sink.file_append_mode(), content="false")
    inspect(sink.file_reopen_with_current_policy(), content="false")
    inspect(sink.file_open_failures(), content="4")
    inspect(sink.file_reopen_append(), content="false")
    inspect(sink.file_append_mode(), content="true")
    inspect(sink.file_open_failures(), content="5")
    inspect(sink.file_reset_failure_counters(), content="true")
    inspect(sink.file_open_failures(), content="0")
    inspect(sink.file_write_failures(), content="0")
    inspect(sink.file_flush_failures(), content="0")
    inspect(sink.file_rotation_failures(), content="0")
  }
}

test "configured logger exposes file sink observability helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-file.log",
        auto_flush=false,
        rotation=Some(file_rotation(64, max_backups=3)),
      ),
    ),
  )
  let state = logger.file_state()
  let runtime_state = logger.file_runtime_state()
  inspect(logger.file_available() == native_files_supported(), content="true")
  inspect(logger.file_path(), content="config-file.log")
  inspect(state.path, content="config-file.log")
  inspect(state.available == logger.file_available(), content="true")
  inspect(state.append == logger.file_append_mode(), content="true")
  inspect(state.auto_flush == logger.file_auto_flush(), content="true")
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="false")
  match runtime_state {
    Some(snapshot) => {
      inspect(snapshot.queued, content="false")
      inspect(snapshot.pending_count, content="0")
      inspect(snapshot.dropped_count, content="0")
      inspect(snapshot.file.path, content="config-file.log")
    }
    None => inspect(false, content="true")
  }
  inspect(logger.file_rotation_enabled(), content="true")
  match logger.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="64")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
  inspect(logger.file_open_failures(), content=if logger.file_available() { "0" } else { "1" })
  inspect(logger.file_write_failures(), content="0")
  inspect(logger.file_flush_failures(), content="0")
  inspect(logger.file_rotation_failures(), content="0")
  ignore(logger.close())
}

test "configured logger file observation helpers stay aligned with runtime sink helpers" {
  let file_logger = build_logger(
    LoggerConfig::new(
      target="config.file.delegate",
      sink=SinkConfig::new(kind=SinkKind::File, path="config-file-delegate.log"),
    ),
  )
  let file_sink = file_logger.sink

  inspect(file_logger.file_available() == file_sink.file_available(), content="true")
  inspect(file_logger.file_path() == file_sink.file_path(), content="true")
  inspect(file_logger.file_open_failures() == file_sink.file_open_failures(), content="true")
  inspect(file_logger.file_write_failures() == file_sink.file_write_failures(), content="true")
  inspect(file_logger.file_flush_failures() == file_sink.file_flush_failures(), content="true")
  inspect(file_logger.file_rotation_failures() == file_sink.file_rotation_failures(), content="true")

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.delegate.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink

  inspect(console_logger.file_available() == console_sink.file_available(), content="true")
  inspect(console_logger.file_path() == console_sink.file_path(), content="true")
  inspect(console_logger.file_open_failures() == console_sink.file_open_failures(), content="true")
  inspect(console_logger.file_write_failures() == console_sink.file_write_failures(), content="true")
  inspect(console_logger.file_flush_failures() == console_sink.file_flush_failures(), content="true")
  inspect(console_logger.file_rotation_failures() == console_sink.file_rotation_failures(), content="true")

  ignore(file_logger.close())
}

test "configured logger file policy helpers stay aligned with runtime sink helpers" {
  let file_logger = build_logger(
    LoggerConfig::new(
      target="config.file.policy.delegate",
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-file-policy-delegate.log",
        append=false,
        auto_flush=true,
        rotation=Some(file_rotation(64, max_backups=2)),
      ),
    ),
  )
  let file_sink = file_logger.sink
  let file_policy = file_logger.file_policy()
  let file_sink_policy = file_sink.file_policy()
  let file_defaults = file_logger.file_default_policy()
  let file_sink_defaults = file_sink.file_default_policy()
  let file_policy_has_rotation = match file_policy.rotation {
    Some(_) => true
    None => false
  }
  let file_sink_policy_has_rotation = match file_sink_policy.rotation {
    Some(_) => true
    None => false
  }
  let file_defaults_has_rotation = match file_defaults.rotation {
    Some(_) => true
    None => false
  }
  let file_sink_defaults_has_rotation = match file_sink_defaults.rotation {
    Some(_) => true
    None => false
  }

  inspect(file_logger.file_append_mode() == file_sink.file_append_mode(), content="true")
  inspect(file_logger.file_auto_flush() == file_sink.file_auto_flush(), content="true")
  inspect(file_logger.file_rotation_enabled() == file_sink.file_rotation_enabled(), content="true")
  inspect(file_logger.file_policy_matches_default() == file_sink.file_policy_matches_default(), content="true")
  inspect(file_policy.append == file_sink_policy.append, content="true")
  inspect(file_policy.auto_flush == file_sink_policy.auto_flush, content="true")
  inspect(file_policy_has_rotation == file_sink_policy_has_rotation, content="true")
  inspect(file_defaults.append == file_sink_defaults.append, content="true")
  inspect(file_defaults.auto_flush == file_sink_defaults.auto_flush, content="true")
  inspect(file_defaults_has_rotation == file_sink_defaults_has_rotation, content="true")

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.policy.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink
  let console_policy = console_logger.file_policy()
  let console_sink_policy = console_sink.file_policy()
  let console_defaults = console_logger.file_default_policy()
  let console_sink_defaults = console_sink.file_default_policy()
  let console_policy_has_rotation = match console_policy.rotation {
    Some(_) => true
    None => false
  }
  let console_sink_policy_has_rotation = match console_sink_policy.rotation {
    Some(_) => true
    None => false
  }
  let console_defaults_has_rotation = match console_defaults.rotation {
    Some(_) => true
    None => false
  }
  let console_sink_defaults_has_rotation = match console_sink_defaults.rotation {
    Some(_) => true
    None => false
  }

  inspect(console_logger.file_append_mode() == console_sink.file_append_mode(), content="true")
  inspect(console_logger.file_auto_flush() == console_sink.file_auto_flush(), content="true")
  inspect(console_logger.file_rotation_enabled() == console_sink.file_rotation_enabled(), content="true")
  inspect(console_logger.file_policy_matches_default() == console_sink.file_policy_matches_default(), content="true")
  inspect(console_policy.append == console_sink_policy.append, content="true")
  inspect(console_policy.auto_flush == console_sink_policy.auto_flush, content="true")
  inspect(console_policy_has_rotation == console_sink_policy_has_rotation, content="true")
  inspect(console_defaults.append == console_sink_defaults.append, content="true")
  inspect(console_defaults.auto_flush == console_sink_defaults.auto_flush, content="true")
  inspect(console_defaults_has_rotation == console_sink_defaults_has_rotation, content="true")

  ignore(file_logger.close())
}

test "configured logger file setters stay aligned with runtime sink setters" {
  let logger = build_logger(
    LoggerConfig::new(
      target="config.file.setters.delegate",
      sink=SinkConfig::new(kind=SinkKind::File, path="config-file-setters-delegate.log"),
    ),
  )
  let sink = logger.sink

  inspect(logger.file_set_append_mode(false) == sink.file_set_append_mode(false), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(logger.file_set_auto_flush(false) == sink.file_set_auto_flush(false), content="true")
  inspect(logger.file_auto_flush() == sink.file_auto_flush(), content="true")

  let rotation = Some(file_rotation(48, max_backups=3))
  inspect(logger.file_set_rotation(rotation) == sink.file_set_rotation(rotation), content="true")
  inspect(logger.file_rotation_enabled() == sink.file_rotation_enabled(), content="true")

  let logger_policy = logger.file_policy()
  let sink_policy = sink.file_policy()
  inspect(logger_policy.append == sink_policy.append, content="true")
  inspect(logger_policy.auto_flush == sink_policy.auto_flush, content="true")
  inspect(match logger_policy.rotation {
    Some(value) => match sink_policy.rotation {
      Some(other) => value.max_bytes == other.max_bytes && value.max_backups == other.max_backups
      None => false
    }
    None => sink_policy.rotation is None
  }, content="true")

  inspect(logger.file_clear_rotation() == sink.file_clear_rotation(), content="true")
  inspect(logger.file_rotation_enabled() == sink.file_rotation_enabled(), content="true")
  inspect(logger.file_policy_matches_default() == sink.file_policy_matches_default(), content="true")

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.setters.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink
  inspect(console_logger.file_set_append_mode(true) == console_sink.file_set_append_mode(true), content="true")
  inspect(console_logger.file_set_auto_flush(true) == console_sink.file_set_auto_flush(true), content="true")
  inspect(console_logger.file_set_rotation(rotation) == console_sink.file_set_rotation(rotation), content="true")
  inspect(console_logger.file_clear_rotation() == console_sink.file_clear_rotation(), content="true")

  ignore(logger.close())
}

test "file state json helpers stringify stable snapshots" {
  let rotation_json = file_rotation_config_to_json(file_rotation(64, max_backups=2))
  let rotation_obj = rotation_json.as_object().unwrap()
  inspect(@json_parser.stringify(rotation_json), content="{\"max_bytes\":64,\"max_backups\":2}")
  inspect(rotation_obj.get("max_bytes").unwrap().as_number().unwrap().to_int(), content="64")
  inspect(rotation_obj.get("max_backups").unwrap().as_number().unwrap().to_int(), content="2")

  let plain = file_sink_state_to_json(
    FileSinkState::new(
      "demo.log",
      available=true,
      append=false,
      auto_flush=true,
      rotation=Some(file_rotation(64, max_backups=2)),
      open_failures=1,
      write_failures=2,
      flush_failures=3,
      rotation_failures=4,
    ),
  )
  let plain_obj = plain.as_object().unwrap()
  let plain_rotation_obj = plain_obj.get("rotation").unwrap().as_object().unwrap()
  inspect(
    @json_parser.stringify(plain),
    content="{\"path\":\"demo.log\",\"available\":true,\"append\":false,\"auto_flush\":true,\"open_failures\":1,\"write_failures\":2,\"flush_failures\":3,\"rotation_failures\":4,\"rotation\":{\"max_bytes\":64,\"max_backups\":2}}",
  )
  inspect(plain_obj.get("path").unwrap().as_string().unwrap(), content="demo.log")
  inspect(plain_obj.get("available").unwrap().as_bool().unwrap(), content="true")
  inspect(plain_obj.get("append").unwrap().as_bool().unwrap(), content="false")
  inspect(plain_obj.get("auto_flush").unwrap().as_bool().unwrap(), content="true")
  inspect(plain_obj.get("open_failures").unwrap().as_number().unwrap().to_int(), content="1")
  inspect(plain_obj.get("write_failures").unwrap().as_number().unwrap().to_int(), content="2")
  inspect(plain_obj.get("flush_failures").unwrap().as_number().unwrap().to_int(), content="3")
  inspect(plain_obj.get("rotation_failures").unwrap().as_number().unwrap().to_int(), content="4")
  inspect(plain_rotation_obj.get("max_bytes").unwrap().as_number().unwrap().to_int(), content="64")
  inspect(plain_rotation_obj.get("max_backups").unwrap().as_number().unwrap().to_int(), content="2")
  inspect(
    stringify_file_sink_state(
      FileSinkState::new(
        "plain.log",
        available=false,
        append=true,
        auto_flush=false,
        rotation=None,
        open_failures=0,
        write_failures=0,
        flush_failures=0,
        rotation_failures=0,
      ),
    ),
    content="{\"path\":\"plain.log\",\"available\":false,\"append\":true,\"auto_flush\":false,\"open_failures\":0,\"write_failures\":0,\"flush_failures\":0,\"rotation_failures\":0,\"rotation\":null}",
  )
}

test "runtime file state json helpers stringify queue snapshots" {
  let runtime_json = runtime_file_state_to_json(
    RuntimeFileState::new(
      FileSinkState::new(
        "queue.log",
        available=true,
        append=true,
        auto_flush=false,
        rotation=None,
        open_failures=0,
        write_failures=1,
        flush_failures=2,
        rotation_failures=3,
      ),
      queued=true,
      pending_count=7,
      dropped_count=5,
    ),
  )
  let runtime_obj = runtime_json.as_object().unwrap()
  let runtime_file_obj = runtime_obj.get("file").unwrap().as_object().unwrap()
  inspect(runtime_obj.get("queued").unwrap().as_bool().unwrap(), content="true")
  inspect(runtime_obj.get("pending_count").unwrap().as_number().unwrap().to_int(), content="7")
  inspect(runtime_obj.get("dropped_count").unwrap().as_number().unwrap().to_int(), content="5")
  inspect(runtime_file_obj.get("path").unwrap().as_string().unwrap(), content="queue.log")
  inspect(runtime_file_obj.get("available").unwrap().as_bool().unwrap(), content="true")
  inspect(runtime_file_obj.get("rotation").unwrap() is @json_parser.JsonValue::Null, content="true")

  let json = stringify_runtime_file_state(
    RuntimeFileState::new(
      FileSinkState::new(
        "queue.log",
        available=true,
        append=true,
        auto_flush=false,
        rotation=None,
        open_failures=0,
        write_failures=1,
        flush_failures=2,
        rotation_failures=3,
      ),
      queued=true,
      pending_count=7,
      dropped_count=5,
    ),
  )
  inspect(
    json,
    content="{\"file\":{\"path\":\"queue.log\",\"available\":true,\"append\":true,\"auto_flush\":false,\"open_failures\":0,\"write_failures\":1,\"flush_failures\":2,\"rotation_failures\":3,\"rotation\":null},\"queued\":true,\"pending_count\":7,\"dropped_count\":5}",
  )
}

test "file sink policy json helpers stringify stable policies" {
  let policy_json = file_sink_policy_to_json(
    FileSinkPolicy::new(
      append=false,
      auto_flush=true,
      rotation=Some(file_rotation(96, max_backups=3)),
    ),
  )
  let policy_obj = policy_json.as_object().unwrap()
  let policy_rotation_obj = policy_obj.get("rotation").unwrap().as_object().unwrap()
  inspect(
    @json_parser.stringify(
      policy_json,
    ),
    content="{\"append\":false,\"auto_flush\":true,\"rotation\":{\"max_bytes\":96,\"max_backups\":3}}",
  )
  inspect(policy_obj.get("append").unwrap().as_bool().unwrap(), content="false")
  inspect(policy_obj.get("auto_flush").unwrap().as_bool().unwrap(), content="true")
  inspect(policy_rotation_obj.get("max_bytes").unwrap().as_number().unwrap().to_int(), content="96")
  inspect(policy_rotation_obj.get("max_backups").unwrap().as_number().unwrap().to_int(), content="3")
  inspect(
    stringify_file_sink_policy(
      FileSinkPolicy::new(append=true, auto_flush=false, rotation=None),
    ),
    content="{\"append\":true,\"auto_flush\":false,\"rotation\":null}",
  )
}

test "configured logger reports disabled rotation when file sink has none" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-no-rotation.log"),
    ),
  )
  inspect(logger.file_rotation_enabled(), content="false")
  inspect(logger.file_rotation_config() is None, content="true")
  match logger.file_runtime_state() {
    Some(snapshot) => inspect(snapshot.queued, content="false")
    None => inspect(false, content="true")
  }
  ignore(logger.close())
}

test "configured non-file logger has no file runtime state" {
  let logger = build_logger(
    LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)),
  )
  inspect(logger.file_runtime_state() is None, content="true")
}

test "configured file logger mirrors backend file capability" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-capability.log"),
    ),
  )
  inspect(logger.file_available() == native_files_supported(), content="true")
  if logger.file_available() {
    inspect(logger.file_state().available, content="true")
    ignore(logger.close())
  } else {
    inspect(logger.file_state().available, content="false")
    inspect(logger.file_flush(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

test "configured logger file setters update file sink policy state" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-setters.log"),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let default_policy = logger.file_default_policy()
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="true")
  inspect(logger.file_rotation_enabled(), content="false")
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(logger.file_policy_matches_default(), content="true")
  inspect(logger.file_set_append_mode(false), content="true")
  inspect(logger.file_append_mode(), content="false")
  inspect(logger.file_set_auto_flush(false), content="true")
  inspect(logger.file_auto_flush(), content="false")
  inspect(logger.file_set_rotation(Some(file_rotation(48, max_backups=4))), content="true")
  inspect(logger.file_rotation_enabled(), content="true")
  match logger.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="48")
      inspect(rotation.max_backups, content="4")
    }
    None => inspect(false, content="true")
  }
  inspect(logger.file_clear_rotation(), content="true")
  inspect(logger.file_rotation_enabled(), content="false")
  inspect(logger.file_rotation_config() is None, content="true")
  inspect(logger.file_reopen(), content=if logger.file_available() { "true" } else { "false" })
  inspect(logger.file_append_mode(), content="false")
  let state = logger.file_state()
  let policy = logger.file_policy()
  inspect(state.append, content="false")
  inspect(state.auto_flush, content="false")
  inspect(state.rotation is None, content="true")
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  inspect(policy.rotation is None, content="true")
  inspect(logger.file_policy_matches_default(), content="false")
  inspect(logger.file_reset_policy(), content="true")
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="true")
  inspect(logger.file_rotation_config() is None, content="true")
  inspect(logger.file_policy_matches_default(), content="true")
  ignore(logger.close())
}

test "configured logger file reopen helpers stay aligned with runtime sink helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-reopen-delegate.log"),
    ),
  )
  let sink = logger.sink

  inspect(logger.file_set_append_mode(false) == sink.file_set_append_mode(false), content="true")
  inspect(logger.file_reopen() == sink.file_reopen(), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(logger.file_reopen_append() == sink.file_reopen_append(), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(logger.file_reopen_truncate() == sink.file_reopen_truncate(), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(logger.file_set_append_mode(true) == sink.file_set_append_mode(true), content="true")
  inspect(logger.file_reopen_with_current_policy() == sink.file_reopen_with_current_policy(), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  inspect(logger.file_reopen(append=Some(false)) == sink.file_reopen(append=Some(false)), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")

  let console_logger = build_logger(
    LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)),
  )
  let console_sink = console_logger.sink
  inspect(console_logger.file_reopen() == console_sink.file_reopen(), content="true")
  inspect(console_logger.file_reopen_with_current_policy() == console_sink.file_reopen_with_current_policy(), content="true")
  inspect(console_logger.file_reopen_append() == console_sink.file_reopen_append(), content="true")
  inspect(console_logger.file_reopen_truncate() == console_sink.file_reopen_truncate(), content="true")

  ignore(logger.close())
}

test "configured logger reset policy restores configured file defaults" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-reset-policy.log",
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(36, max_backups=2)),
      ),
    ),
  )
  let default_policy = logger.file_default_policy()
  inspect(default_policy.append, content="false")
  inspect(default_policy.auto_flush, content="false")
  inspect(logger.file_policy_matches_default(), content="true")
  inspect(logger.file_set_append_mode(true), content="true")
  inspect(logger.file_set_auto_flush(true), content="true")
  inspect(logger.file_clear_rotation(), content="true")
  inspect(logger.file_reset_policy(), content="true")
  inspect(logger.file_append_mode(), content="false")
  inspect(logger.file_auto_flush(), content="false")
  inspect(logger.file_policy_matches_default(), content="true")
  match logger.file_rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="36")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  ignore(logger.close())
}

test "configured logger set policy applies bundled runtime file policy" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-set-policy.log"),
    ),
  )
  let default_policy = logger.file_default_policy()
  inspect(
    logger.file_set_policy(
      FileSinkPolicy::new(
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(22, max_backups=3)),
      ),
    ),
    content="true",
  )
  let policy = logger.file_policy()
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  match policy.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="22")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(logger.file_policy_matches_default(), content="false")
  ignore(logger.close())
}

test "configured non-file logger cannot reset file policy" {
  let logger = build_logger(LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)))
  inspect(logger.file_reset_policy(), content="false")
  inspect(logger.file_policy().append, content="false")
  inspect(logger.file_default_policy().append, content="false")
  inspect(logger.file_set_policy(FileSinkPolicy::new()), content="false")
  inspect(logger.file_policy_matches_default(), content="false")
}

test "configured logger can reopen built file sink" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-reopen.log"),
    ),
  )
  if logger.file_available() {
    inspect(logger.close(), content="true")
    inspect(logger.file_reopen_append(), content="true")
    inspect(logger.file_available(), content="true")
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_open_failures(), content="0")
    logger.info("reopened from config")
    inspect(logger.file_write_failures(), content="0")
    inspect(logger.file_reopen_truncate(), content="true")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen(), content="true")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen_with_current_policy(), content="true")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen_append(), content="true")
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_reset_failure_counters(), content="true")
    inspect(logger.file_open_failures(), content="0")
    inspect(logger.file_write_failures(), content="0")
    inspect(logger.file_flush_failures(), content="0")
    inspect(logger.file_rotation_failures(), content="0")
    inspect(logger.close(), content="true")
  } else {
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_open_failures(), content="1")
    logger.info("dropped")
    inspect(logger.file_write_failures(), content="1")
    inspect(logger.file_reopen_append(), content="false")
    inspect(logger.file_open_failures(), content="2")
    inspect(logger.file_reopen_truncate(), content="false")
    inspect(logger.file_append_mode(), content="false")
    inspect(logger.file_reopen_with_current_policy(), content="false")
    inspect(logger.file_open_failures(), content="4")
    inspect(logger.file_reopen_append(), content="false")
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_open_failures(), content="5")
    inspect(logger.file_reset_failure_counters(), content="true")
    inspect(logger.file_open_failures(), content="0")
    inspect(logger.file_write_failures(), content="0")
    inspect(logger.file_flush_failures(), content="0")
    inspect(logger.file_rotation_failures(), content="0")
  }
}

test "configured non-file logger cannot reset file failure counters" {
  let logger = build_logger(LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)))
  inspect(logger.file_reset_failure_counters(), content="false")
}

test "configured logger file reset helpers stay aligned with runtime sink helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="config-reset-delegate.log",
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(40, max_backups=2)),
      ),
    ),
  )
  let sink = logger.sink

  ignore(logger.file_set_append_mode(true))
  ignore(sink.file_set_append_mode(true))
  ignore(logger.file_set_auto_flush(true))
  ignore(sink.file_set_auto_flush(true))
  ignore(logger.file_set_rotation(None))
  ignore(sink.file_set_rotation(None))

  inspect(logger.file_reset_policy() == sink.file_reset_policy(), content="true")
  inspect(logger.file_policy_matches_default() == sink.file_policy_matches_default(), content="true")
  inspect(logger.file_append_mode() == sink.file_append_mode(), content="true")
  inspect(logger.file_auto_flush() == sink.file_auto_flush(), content="true")

  inspect(logger.file_reset_failure_counters() == sink.file_reset_failure_counters(), content="true")
  inspect(logger.file_open_failures() == sink.file_open_failures(), content="true")
  inspect(logger.file_write_failures() == sink.file_write_failures(), content="true")
  inspect(logger.file_flush_failures() == sink.file_flush_failures(), content="true")
  inspect(logger.file_rotation_failures() == sink.file_rotation_failures(), content="true")

  let console_logger = build_logger(LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console)))
  let console_sink = console_logger.sink
  inspect(console_logger.file_reset_policy() == console_sink.file_reset_policy(), content="true")
  inspect(
    console_logger.file_reset_failure_counters() == console_sink.file_reset_failure_counters(),
    content="true",
  )

  ignore(logger.close())
}

test "configured logger exposes file flush and close helpers" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-control.log"),
    ),
  )
  if logger.file_available() {
    logger.info("before flush")
    inspect(logger.file_flush(), content="true")
    inspect(logger.file_close(), content="true")
    inspect(logger.file_available(), content="false")
    inspect(logger.file_flush(), content="false")
  } else {
    inspect(logger.file_flush(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

test "configured logger file flush and close stay aligned with runtime sink helpers" {
  let file_config = LoggerConfig::new(
    sink=SinkConfig::new(kind=SinkKind::File, path="config-file-helper-delegate.log"),
  )
  let file_logger = build_logger(file_config)
  let file_sink = build_logger(file_config).sink

  inspect(file_logger.file_flush() == file_sink.file_flush(), content="true")
  inspect(file_logger.file_close() == file_sink.file_close(), content="true")

  let console_config = LoggerConfig::new(sink=SinkConfig::new(kind=SinkKind::Console))
  let console_logger = build_logger(console_config)
  let console_sink = build_logger(console_config).sink

  inspect(console_logger.file_flush() == console_sink.file_flush(), content="true")
  inspect(console_logger.file_close() == console_sink.file_close(), content="true")
}

test "configured logger file state helpers stay aligned with runtime sink helpers" {
  let file_logger = build_logger(
    LoggerConfig::new(
      target="config.file.state.delegate",
      sink=SinkConfig::new(kind=SinkKind::File, path="config-file-state-delegate.log"),
    ),
  )
  let file_sink = file_logger.sink
  let file_state = file_logger.file_state()
  let file_sink_state = file_sink.file_state()

  inspect(file_state.path == file_sink_state.path, content="true")
  inspect(file_state.available == file_sink_state.available, content="true")
  inspect(file_state.append == file_sink_state.append, content="true")
  inspect(file_state.auto_flush == file_sink_state.auto_flush, content="true")
  inspect(file_state.open_failures == file_sink_state.open_failures, content="true")
  inspect(file_state.write_failures == file_sink_state.write_failures, content="true")
  inspect(file_state.flush_failures == file_sink_state.flush_failures, content="true")
  inspect(file_state.rotation_failures == file_sink_state.rotation_failures, content="true")
  inspect(match file_state.rotation {
    Some(rotation) => match file_sink_state.rotation {
      Some(other) => rotation.max_bytes == other.max_bytes && rotation.max_backups == other.max_backups
      None => false
    }
    None => file_sink_state.rotation is None
  }, content="true")
  inspect(
    (file_logger.file_runtime_state() is None) == (file_sink.file_runtime_state() is None),
    content="true",
  )

  let queued_logger = build_logger(
    LoggerConfig::new(
      target="config.file.runtime.delegate",
      sink=SinkConfig::new(kind=SinkKind::File, path="config-file-runtime-delegate.log"),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let queued_sink = queued_logger.sink
  queued_logger.info("one")
  queued_logger.info("two")
  let queued_state = queued_logger.file_state()
  let queued_sink_state = queued_sink.file_state()

  inspect(queued_state.path == queued_sink_state.path, content="true")
  inspect(queued_state.available == queued_sink_state.available, content="true")
  inspect(queued_state.append == queued_sink_state.append, content="true")
  inspect(queued_state.auto_flush == queued_sink_state.auto_flush, content="true")
  inspect(queued_state.open_failures == queued_sink_state.open_failures, content="true")
  inspect(queued_state.write_failures == queued_sink_state.write_failures, content="true")
  inspect(queued_state.flush_failures == queued_sink_state.flush_failures, content="true")
  inspect(queued_state.rotation_failures == queued_sink_state.rotation_failures, content="true")
  inspect(match queued_state.rotation {
    Some(rotation) => match queued_sink_state.rotation {
      Some(other) => rotation.max_bytes == other.max_bytes && rotation.max_backups == other.max_backups
      None => false
    }
    None => queued_sink_state.rotation is None
  }, content="true")

  match (queued_logger.file_runtime_state(), queued_sink.file_runtime_state()) {
    (Some(snapshot), Some(sink_snapshot)) => {
      inspect(snapshot.file.path == sink_snapshot.file.path, content="true")
      inspect(snapshot.file.available == sink_snapshot.file.available, content="true")
      inspect(snapshot.file.append == sink_snapshot.file.append, content="true")
      inspect(snapshot.file.auto_flush == sink_snapshot.file.auto_flush, content="true")
      inspect(snapshot.file.open_failures == sink_snapshot.file.open_failures, content="true")
      inspect(snapshot.file.write_failures == sink_snapshot.file.write_failures, content="true")
      inspect(snapshot.file.flush_failures == sink_snapshot.file.flush_failures, content="true")
      inspect(snapshot.file.rotation_failures == sink_snapshot.file.rotation_failures, content="true")
      inspect(snapshot.queued == sink_snapshot.queued, content="true")
      inspect(snapshot.pending_count == sink_snapshot.pending_count, content="true")
      inspect(snapshot.dropped_count == sink_snapshot.dropped_count, content="true")
      inspect(match snapshot.file.rotation {
        Some(rotation) => match sink_snapshot.file.rotation {
          Some(other) => rotation.max_bytes == other.max_bytes && rotation.max_backups == other.max_backups
          None => false
        }
        None => sink_snapshot.file.rotation is None
      }, content="true")
    }
    _ => inspect(false, content="true")
  }

  let console_logger = build_logger(
    LoggerConfig::new(
      target="config.file.state.console",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let console_sink = console_logger.sink
  let console_state = console_logger.file_state()
  let console_sink_state = console_sink.file_state()

  inspect(console_state.path == console_sink_state.path, content="true")
  inspect(console_state.available == console_sink_state.available, content="true")
  inspect(console_state.append == console_sink_state.append, content="true")
  inspect(console_state.auto_flush == console_sink_state.auto_flush, content="true")
  inspect(console_state.open_failures == console_sink_state.open_failures, content="true")
  inspect(console_state.write_failures == console_sink_state.write_failures, content="true")
  inspect(console_state.flush_failures == console_sink_state.flush_failures, content="true")
  inspect(console_state.rotation_failures == console_sink_state.rotation_failures, content="true")
  inspect((console_state.rotation is None) == (console_sink_state.rotation is None), content="true")
  inspect(
    (console_logger.file_runtime_state() is None) == (console_sink.file_runtime_state() is None),
    content="true",
  )

  ignore(file_logger.close())
  ignore(queued_logger.close())
}

test "configured queued file logger flushes queue through file helper" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-queued-file.log"),
      queue=Some(QueueConfig::new(4, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  logger.info("one")
  logger.info("two")
  match logger.file_runtime_state() {
    Some(snapshot) => {
      inspect(snapshot.queued, content="true")
      inspect(snapshot.pending_count, content="2")
      inspect(snapshot.dropped_count, content="0")
    }
    None => inspect(false, content="true")
  }
  if logger.file_available() {
    inspect(logger.pending_count(), content="2")
    inspect(logger.file_flush(), content="true")
    inspect(logger.pending_count(), content="0")
    match logger.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(logger.file_close(), content="true")
  } else {
    inspect(logger.pending_count(), content="2")
    inspect(logger.file_flush(), content="false")
    inspect(logger.pending_count(), content="0")
    match logger.file_runtime_state() {
      Some(snapshot) => inspect(snapshot.pending_count, content="0")
      None => inspect(false, content="true")
    }
    inspect(logger.file_close(), content="false")
  }
}

test "logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Warn,
    target="sync.default",
  ).with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="sync.override",
  )
  inspect(captured_target.val, content="sync.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="sync.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
    }),
    min_level=Level::Trace,
    target="sync.helpers",
  ).with_context_fields([field("service", "bitlogger")])

  logger.trace("trace", fields=[field("mode", "trace")])
  logger.debug("debug", fields=[field("mode", "debug")])
  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="5")
  inspect(captured_levels.val[0], content="TRACE")
  inspect(captured_levels.val[1], content="DEBUG")
  inspect(captured_levels.val[2], content="INFO")
  inspect(captured_levels.val[3], content="WARN")
  inspect(captured_levels.val[4], content="ERROR")
  inspect(captured_targets.val.length(), content="5")
  inspect(captured_targets.val[0], content="sync.helpers")
  inspect(captured_targets.val[1], content="sync.helpers")
  inspect(captured_targets.val[2], content="sync.helpers")
  inspect(captured_targets.val[3], content="sync.helpers")
  inspect(captured_targets.val[4], content="sync.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[3].length(), content="2")
  inspect(captured_fields.val[4].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="trace")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="debug")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="info")
  inspect(captured_fields.val[3][0].key, content="service")
  inspect(captured_fields.val[3][1].value, content="warn")
  inspect(captured_fields.val[4][0].key, content="service")
  inspect(captured_fields.val[4][1].value, content="error")
}

test "library logger keeps a smaller stable facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = LibraryLogger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="svc",
  ).with_context_fields([field("service", "bitlogger")]).child("worker")
  logger.info("ready", fields=[field("mode", "test")])
  inspect(captured_target.val, content="svc.worker")
  inspect(captured_message.val, content="ready")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[1].key, content="mode")
}

test "library logger context binding unwraps to context sink shape" {
  let logger = LibraryLogger::new(console_sink(), min_level=Level::Warn, target="lib.ctx")
    .with_context_fields([field("service", "bitlogger"), field("scope", "sdk")])
  let full = logger.to_logger()

  inspect(full.target, content="lib.ctx")
  inspect(full.timestamp, content="false")
  inspect(full.is_enabled(Level::Error), content="true")
  inspect(full.is_enabled(Level::Info), content="false")
  inspect(full.sink.context_fields.length(), content="2")
  inspect(full.sink.context_fields[0].key, content="service")
  inspect(full.sink.context_fields[0].value, content="bitlogger")
  inspect(full.sink.context_fields[1].key, content="scope")
  inspect(full.sink.context_fields[1].value, content="sdk")
}

test "library logger bind matches context facade contract" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_timestamp.val = rec.timestamp_ms
      captured_fields.val = rec.fields
    }),
    min_level=Level::Warn,
    target="lib.bind",
  )
    .with_timestamp()
    .to_library_logger()
    .bind([field("service", "bitlogger")])
  let full = logger.to_logger()

  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.bind")
  inspect(full.timestamp, content="true")
  inspect(full.sink.context_fields.length(), content="1")
  inspect(full.sink.context_fields[0].key, content="service")
  inspect(full.sink.context_fields[0].value, content="bitlogger")

  logger.error("bound", fields=[field("mode", "test")])
  inspect(captured_target.val, content="lib.bind")
  inspect(captured_timestamp.val > 0UL, content="true")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")
}

test "library logger with_target preserves facade state while replacing target" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_timestamp.val = rec.timestamp_ms
    }),
    min_level=Level::Warn,
    target="lib.base",
  )
    .with_timestamp()
    .to_library_logger()
    .with_target("lib.retarget")
  let full = logger.to_logger()

  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.retarget")
  inspect(full.timestamp, content="true")

  logger.error("retargeted")
  inspect(captured_target.val, content="lib.retarget")
  inspect(captured_timestamp.val > 0UL, content="true")
}

test "library logger child composes target through facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_timestamp.val = rec.timestamp_ms
    }),
    min_level=Level::Warn,
    target="sdk",
  )
    .with_timestamp()
    .to_library_logger()
    .child("worker")
  let full = logger.to_logger()

  inspect(full.target, content="sdk.worker")
  inspect(full.timestamp, content="true")
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")

  logger.error("child")
  inspect(captured_target.val, content="sdk.worker")
  inspect(captured_timestamp.val > 0UL, content="true")

  let root_child = LibraryLogger::new(console_sink()).child("worker")
  inspect(root_child.to_logger().target, content="worker")

  let keep_parent = LibraryLogger::new(console_sink(), target="sdk").child("")
  inspect(keep_parent.to_logger().target, content="sdk")
}

test "library logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = LibraryLogger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Warn,
    target="lib.default",
  )
    .with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="lib.override",
  )
  inspect(captured_target.val, content="lib.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="lib.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "library logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = LibraryLogger::new(
    callback_sink(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
    }),
    min_level=Level::Info,
    target="lib.helpers",
  )
    .bind([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="lib.helpers")
  inspect(captured_targets.val[1], content="lib.helpers")
  inspect(captured_targets.val[2], content="lib.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

test "library logger can unwrap to full logger when needed" {
  let base = LibraryLogger::new(console_sink(), min_level=Level::Warn, target="lib")
  let full = base.to_logger().with_timestamp()
  inspect(base.is_enabled(Level::Error), content="true")
  inspect(base.is_enabled(Level::Info), content="false")
  inspect(full.timestamp, content="true")
  inspect(full.target, content="lib")
}

test "library logger can be built from configured runtime path" {
  let logger = build_library_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="lib.config",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let full = logger.to_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.config")
}

test "library logger builder log supports per-call target override through facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = build_library_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="lib.config.default",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
    .to_logger()
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .to_library_logger()
    .bind([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="lib.config.override",
  )
  inspect(captured_target.val, content="lib.config.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="lib.config.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "library logger builder severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = build_library_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="lib.config.helpers",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
    .to_logger()
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .to_library_logger()
    .bind([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="lib.config.helpers")
  inspect(captured_targets.val[1], content="lib.config.helpers")
  inspect(captured_targets.val[2], content="lib.config.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

test "library logger builder unwrap matches direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="lib.config.same-build",
    timestamp=true,
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
    sink=SinkConfig::new(kind=SinkKind::Console),
  )
  let logger = build_library_logger(config)
  let full = logger.to_logger()
  let configured = build_logger(config)

  inspect(full.target, content=configured.target)
  inspect(full.timestamp == configured.timestamp, content="true")
  inspect(logger.is_enabled(Level::Error) == configured.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info) == configured.is_enabled(Level::Info), content="true")
  let full_sink_kind = match full.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  let configured_sink_kind = match configured.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  inspect(full_sink_kind == configured_sink_kind, content="true")

  full.error("one")
  full.error("two")
  full.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(full.flush() == configured.flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")
}

test "library logger builder unwrap preserves file runtime helpers" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="lib.file.same-build",
    sink=SinkConfig::new(kind=SinkKind::File, path="lib-file-same-build.log"),
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
  )
  let logger = build_library_logger(config)
  let full = logger.to_logger()
  let configured = build_logger(config)

  full.error("one")
  full.error("two")
  full.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(full.file_available() == configured.file_available(), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_auto_flush() == configured.file_auto_flush(), content="true")

  let full_state = full.file_state()
  let configured_state = configured.file_state()
  inspect(full_state.path == configured_state.path, content="true")
  inspect(full_state.available == configured_state.available, content="true")
  inspect(full_state.append == configured_state.append, content="true")
  inspect(full_state.auto_flush == configured_state.auto_flush, content="true")
  inspect(full_state.open_failures == configured_state.open_failures, content="true")
  inspect(full_state.write_failures == configured_state.write_failures, content="true")
  inspect(full_state.flush_failures == configured_state.flush_failures, content="true")
  inspect(full_state.rotation_failures == configured_state.rotation_failures, content="true")

  match (full.file_runtime_state(), configured.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(full.file_flush() == configured.file_flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.file_close() == configured.file_close(), content="true")
}

test "library logger builder unwrap preserves file controls" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="lib.file.controls.same-build",
    sink=SinkConfig::new(kind=SinkKind::File, path="lib-file-controls-same-build.log"),
  )
  let logger = build_library_logger(config)
  let full = logger.to_logger()
  let configured = build_logger(config)

  inspect(full.file_set_append_mode(false) == configured.file_set_append_mode(false), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_set_auto_flush(false) == configured.file_set_auto_flush(false), content="true")
  inspect(full.file_auto_flush() == configured.file_auto_flush(), content="true")

  let rotation = Some(file_rotation(48, max_backups=3))
  inspect(full.file_set_rotation(rotation) == configured.file_set_rotation(rotation), content="true")
  inspect(full.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")

  let full_policy = full.file_policy()
  let configured_policy = configured.file_policy()
  inspect(full_policy.append == configured_policy.append, content="true")
  inspect(full_policy.auto_flush == configured_policy.auto_flush, content="true")
  inspect(match full_policy.rotation {
    Some(value) => match configured_policy.rotation {
      Some(other) => value.max_bytes == other.max_bytes && value.max_backups == other.max_backups
      None => false
    }
    None => configured_policy.rotation is None
  }, content="true")

  inspect(full.file_reopen_append() == configured.file_reopen_append(), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_reopen_truncate() == configured.file_reopen_truncate(), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_reopen_with_current_policy() == configured.file_reopen_with_current_policy(), content="true")

  inspect(full.file_clear_rotation() == configured.file_clear_rotation(), content="true")
  inspect(full.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")
  inspect(full.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")
  inspect(full.file_reset_policy() == configured.file_reset_policy(), content="true")
  inspect(full.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")
  inspect(full.file_reset_failure_counters() == configured.file_reset_failure_counters(), content="true")

  inspect(full.file_close() == configured.file_close(), content="true")
}

test "library logger can be parsed and built from config text" {
  let logger = parse_and_build_library_logger(
    "{\"min_level\":\"warn\",\"target\":\"lib.json\",\"sink\":{\"kind\":\"console\"}}",
  )
  let full = logger.to_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.json")
}

test "parsed library logger log supports per-call target override through facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = parse_and_build_library_logger(
    "{\"min_level\":\"warn\",\"target\":\"lib.json.default\",\"sink\":{\"kind\":\"console\"}}",
  )
    .to_logger()
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .to_library_logger()
    .bind([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="lib.json.override",
  )
  inspect(captured_target.val, content="lib.json.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="lib.json.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "parsed library logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = parse_and_build_library_logger(
    "{\"min_level\":\"info\",\"target\":\"lib.json.helpers\",\"sink\":{\"kind\":\"console\"}}",
  )
    .to_logger()
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .to_library_logger()
    .bind([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="lib.json.helpers")
  inspect(captured_targets.val[1], content="lib.json.helpers")
  inspect(captured_targets.val[2], content="lib.json.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

test "library logger parse-build unwrap matches parsed direct builder behavior" {
  let raw = "{\"min_level\":\"warn\",\"target\":\"lib.json.same-build\",\"timestamp\":true,\"queue\":{\"max_pending\":2,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}}"
  let logger = parse_and_build_library_logger(raw)
  let full = logger.to_logger()
  let configured = parse_and_build_logger(raw)

  inspect(full.target, content=configured.target)
  inspect(full.timestamp == configured.timestamp, content="true")
  inspect(logger.is_enabled(Level::Error) == configured.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info) == configured.is_enabled(Level::Info), content="true")
  let full_sink_kind = match full.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  let configured_sink_kind = match configured.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  inspect(full_sink_kind == configured_sink_kind, content="true")

  full.error("one")
  full.error("two")
  full.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(full.flush() == configured.flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")
}

test "library logger parse-build unwrap preserves file runtime helpers" {
  let raw = "{\"min_level\":\"warn\",\"target\":\"lib.json.file.same-build\",\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"},\"sink\":{\"kind\":\"file\",\"path\":\"lib-json-file-same-build.log\"}}"
  let logger = parse_and_build_library_logger(raw)
  let full = logger.to_logger()
  let configured = parse_and_build_logger(raw)

  full.error("one")
  full.error("two")
  full.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(full.file_available() == configured.file_available(), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_auto_flush() == configured.file_auto_flush(), content="true")

  let full_state = full.file_state()
  let configured_state = configured.file_state()
  inspect(full_state.path == configured_state.path, content="true")
  inspect(full_state.available == configured_state.available, content="true")
  inspect(full_state.append == configured_state.append, content="true")
  inspect(full_state.auto_flush == configured_state.auto_flush, content="true")
  inspect(full_state.open_failures == configured_state.open_failures, content="true")
  inspect(full_state.write_failures == configured_state.write_failures, content="true")
  inspect(full_state.flush_failures == configured_state.flush_failures, content="true")
  inspect(full_state.rotation_failures == configured_state.rotation_failures, content="true")

  match (full.file_runtime_state(), configured.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(full.file_flush() == configured.file_flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.file_close() == configured.file_close(), content="true")
}

test "library logger parse-build unwrap preserves file controls" {
  let raw = "{\"min_level\":\"warn\",\"target\":\"lib.json.file.controls.same-build\",\"sink\":{\"kind\":\"file\",\"path\":\"lib-json-file-controls-same-build.log\"}}"
  let logger = parse_and_build_library_logger(raw)
  let full = logger.to_logger()
  let configured = parse_and_build_logger(raw)

  inspect(full.file_set_append_mode(false) == configured.file_set_append_mode(false), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_set_auto_flush(false) == configured.file_set_auto_flush(false), content="true")
  inspect(full.file_auto_flush() == configured.file_auto_flush(), content="true")

  let rotation = Some(file_rotation(40, max_backups=2))
  inspect(full.file_set_rotation(rotation) == configured.file_set_rotation(rotation), content="true")
  inspect(full.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")
  inspect(full.file_reopen(append=Some(false)) == configured.file_reopen(append=Some(false)), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_reopen_append() == configured.file_reopen_append(), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_clear_rotation() == configured.file_clear_rotation(), content="true")
  inspect(full.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")
  inspect(full.file_reset_policy() == configured.file_reset_policy(), content="true")
  inspect(full.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")
  inspect(full.file_reset_failure_counters() == configured.file_reset_failure_counters(), content="true")

  inspect(full.file_close() == configured.file_close(), content="true")
}

test "parsed library logger unwrap preserves configured runtime path" {
  let logger = parse_and_build_library_logger(
    "{\"min_level\":\"warn\",\"target\":\"lib.json.runtime\",\"timestamp\":true,\"queue\":{\"max_pending\":3,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}}",
  )
  let full = logger.to_logger()

  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.json.runtime")
  inspect(full.timestamp, content="true")

  full.error("one")
  full.error("two")
  inspect(match full.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")
  inspect(full.sink.pending_count(), content="2")
  inspect(full.sink.dropped_count(), content="0")
  inspect(full.sink.drain(max_items=1), content="1")
  inspect(full.sink.pending_count(), content="1")
  inspect(full.sink.flush(), content="1")
  inspect(full.sink.pending_count(), content="0")
}

test "configured logger can project to library logger" {
  let configured = build_logger(
    LoggerConfig::new(min_level=Level::Warn, target="lib.projected"),
  )
  let logger = configured.to_library_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.to_logger().target, content="lib.projected")
}

test "logger projection preserves sync composition state through library facade" {
  let captured_target : Ref[String] = Ref("")
  let captured_timestamp : Ref[UInt64] = Ref(0UL)
  let captured_fields : Ref[Array[Field]] = Ref([])
  let base = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_timestamp.val = rec.timestamp_ms
      captured_fields.val = rec.fields
    }),
    min_level=Level::Warn,
    target="lib.projected.state",
  )
    .with_timestamp()
    .with_context_fields([field("service", "bitlogger")])
  let projected = base.to_library_logger()
  let full = projected.to_logger()

  inspect(projected.is_enabled(Level::Error), content="true")
  inspect(projected.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.projected.state")
  inspect(full.timestamp, content="true")
  full.error("boom", fields=[field("mode", "test")])
  inspect(captured_target.val, content="lib.projected.state")
  inspect(captured_timestamp.val > 0UL, content="true")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
}

test "configured logger projection preserves runtime helpers through unwrap" {
  let projected = build_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="lib.projected.runtime",
      sink=SinkConfig::new(kind=SinkKind::Console),
      queue=Some(QueueConfig::new(3, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  ).to_library_logger()
  let full = projected.to_logger()

  inspect(projected.is_enabled(Level::Error), content="true")
  inspect(projected.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.projected.runtime")
  full.error("one")
  full.error("two")
  inspect(match full.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")
  inspect(full.sink.pending_count(), content="2")
  inspect(full.sink.dropped_count(), content="0")
  inspect(full.sink.drain(max_items=1), content="1")
  inspect(full.sink.pending_count(), content="1")
  inspect(full.sink.flush(), content="1")
  inspect(full.sink.pending_count(), content="0")
}

test "configured logger projection preserves file runtime helpers through unwrap" {
  let configured = build_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="lib.projected.file",
      sink=SinkConfig::new(kind=SinkKind::File, path="lib-projected-file.log"),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )
  let projected = configured.to_library_logger()
  let full = projected.to_logger()

  inspect(projected.is_enabled(Level::Error), content="true")
  inspect(projected.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.projected.file")

  full.error("one")
  full.error("two")
  full.error("three")
  inspect(full.pending_count() == configured.pending_count(), content="true")
  inspect(full.dropped_count() == configured.dropped_count(), content="true")
  inspect(full.file_available() == configured.file_available(), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_auto_flush() == configured.file_auto_flush(), content="true")

  let full_state = full.file_state()
  let configured_state = configured.file_state()
  inspect(full_state.path == configured_state.path, content="true")
  inspect(full_state.available == configured_state.available, content="true")
  inspect(full_state.append == configured_state.append, content="true")
  inspect(full_state.auto_flush == configured_state.auto_flush, content="true")
  inspect(full_state.open_failures == configured_state.open_failures, content="true")
  inspect(full_state.write_failures == configured_state.write_failures, content="true")
  inspect(full_state.flush_failures == configured_state.flush_failures, content="true")
  inspect(full_state.rotation_failures == configured_state.rotation_failures, content="true")

  match (full.file_runtime_state(), configured.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(full.file_set_append_mode(false) == configured.file_set_append_mode(false), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_set_auto_flush(false) == configured.file_set_auto_flush(false), content="true")
  inspect(full.file_auto_flush() == configured.file_auto_flush(), content="true")
  inspect(
    full.file_set_rotation(Some(file_rotation(36, max_backups=2))) ==
      configured.file_set_rotation(Some(file_rotation(36, max_backups=2))),
    content="true",
  )
  inspect(full.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")
  inspect(full.file_reopen_append() == configured.file_reopen_append(), content="true")
  inspect(full.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(full.file_clear_rotation() == configured.file_clear_rotation(), content="true")
  inspect(full.file_reset_policy() == configured.file_reset_policy(), content="true")
  inspect(full.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")
  inspect(full.file_reset_failure_counters() == configured.file_reset_failure_counters(), content="true")
  inspect(full.file_flush() == configured.file_flush(), content="true")
  inspect(full.pending_count() == configured.pending_count(), content="true")

  let was_available = configured.file_available()
  inspect(configured.file_close() == was_available, content="true")
  inspect(full.file_available(), content="false")
  inspect(configured.file_available(), content="false")
  inspect(full.file_close(), content="false")
}

test "default library logger mirrors shared sync defaults" {
  set_default_min_level(Level::Warn)
  set_default_target("lib.default")
  let logger = default_library_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.to_logger().target, content="lib.default")
}

test "default library logger snapshots shared defaults at creation time" {
  set_default_min_level(Level::Warn)
  set_default_target("lib.before")
  let before = default_library_logger()

  set_default_min_level(Level::Debug)
  set_default_target("lib.after")
  let after = default_library_logger()

  inspect(before.is_enabled(Level::Error), content="true")
  inspect(before.is_enabled(Level::Info), content="false")
  inspect(before.to_logger().target, content="lib.before")

  inspect(after.is_enabled(Level::Error), content="true")
  inspect(after.is_enabled(Level::Info), content="true")
  inspect(after.to_logger().target, content="lib.after")
}

test "application logger aliases configured runtime entry" {
  let logger = build_application_logger(
    LoggerConfig::new(min_level=Level::Warn, target="app.runtime"),
  )
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.target, content="app.runtime")
}

test "application logger builder matches direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="app.runtime.same-build",
    timestamp=true,
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
    sink=SinkConfig::new(kind=SinkKind::Console),
  )
  let application = build_application_logger(config)
  let configured = build_logger(config)

  inspect(application.target, content=configured.target)
  inspect(application.timestamp, content="true")
  inspect(configured.timestamp, content="true")
  inspect(application.is_enabled(Level::Error) == configured.is_enabled(Level::Error), content="true")
  inspect(application.is_enabled(Level::Info) == configured.is_enabled(Level::Info), content="true")
  let application_sink_kind = match application.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  let configured_sink_kind = match configured.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  inspect(application_sink_kind == configured_sink_kind, content="true")

  application.error("one")
  application.error("two")
  application.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(application.pending_count() == configured.pending_count(), content="true")
  inspect(application.dropped_count() == configured.dropped_count(), content="true")
  inspect(application.flush() == configured.flush(), content="true")
  inspect(application.pending_count() == configured.pending_count(), content="true")
}

test "configured logger keeps broader logger composition surface" {
  let logger : ConfiguredLogger = build_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="configured.compose",
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let derived = logger.with_timestamp().child("worker")

  inspect(derived.target, content="configured.compose.worker")
  inspect(derived.timestamp, content="true")
  inspect(derived.is_enabled(Level::Error), content="true")
  inspect(derived.is_enabled(Level::Info), content="false")
  inspect(match derived.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")

  derived.error("one")
  derived.error("two")
  inspect(derived.pending_count(), content="2")
  inspect(derived.dropped_count(), content="0")
  inspect(derived.flush(), content="2")
}

test "configured logger build supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="configured.default",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="configured.override",
  )
  inspect(captured_target.val, content="configured.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="configured.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "configured logger build severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = build_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="configured.helpers",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="configured.helpers")
  inspect(captured_targets.val[1], content="configured.helpers")
  inspect(captured_targets.val[2], content="configured.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

test "application logger keeps configured runtime helper surface" {
  let logger : ApplicationLogger = build_application_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="app.alias.helpers",
      sink=SinkConfig::new(kind=SinkKind::File, path="app-alias.log"),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
    ),
  )

  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.file_policy().append, content="true")
  inspect(logger.file_runtime_state() is None, content="false")
  inspect(logger.flush(), content="2")
  inspect(logger.pending_count(), content="0")

  if logger.file_available() {
    inspect(logger.file_flush(), content="true")
    inspect(logger.file_close(), content="true")
  } else {
    inspect(logger.file_flush(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

test "application logger build supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = build_application_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="app.config.default",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="app.config.override",
  )
  inspect(captured_target.val, content="app.config.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="app.config.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "application logger build severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = build_application_logger(
    LoggerConfig::new(
      min_level=Level::Info,
      target="app.config.helpers",
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="app.config.helpers")
  inspect(captured_targets.val[1], content="app.config.helpers")
  inspect(captured_targets.val[2], content="app.config.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

test "application logger keeps broader logger composition surface" {
  let logger : ApplicationLogger = build_application_logger(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="app.compose",
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
      sink=SinkConfig::new(kind=SinkKind::Console),
    ),
  )
  let derived = logger.with_timestamp().child("worker")

  inspect(derived.target, content="app.compose.worker")
  inspect(derived.timestamp, content="true")
  inspect(derived.is_enabled(Level::Error), content="true")
  inspect(derived.is_enabled(Level::Info), content="false")
  inspect(match derived.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")

  derived.error("one")
  derived.error("two")
  inspect(derived.pending_count(), content="2")
  inspect(derived.dropped_count(), content="0")
  inspect(derived.flush(), content="2")
  inspect(derived.pending_count(), content="0")
}

test "application logger can be built from config text" {
  let logger = parse_and_build_application_logger(
    "{\"min_level\":\"warn\",\"target\":\"app.json\",\"sink\":{\"kind\":\"console\"}}",
  )
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.target, content="app.json")
}

test "parsed application logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = parse_and_build_application_logger(
    "{\"min_level\":\"warn\",\"target\":\"app.json.default\",\"sink\":{\"kind\":\"console\"}}",
  )
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="app.json.override",
  )
  inspect(captured_target.val, content="app.json.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="app.json.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "parsed application logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = parse_and_build_application_logger(
    "{\"min_level\":\"info\",\"target\":\"app.json.helpers\",\"sink\":{\"kind\":\"console\"}}",
  )
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="app.json.helpers")
  inspect(captured_targets.val[1], content="app.json.helpers")
  inspect(captured_targets.val[2], content="app.json.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

test "application logger parse-build matches parsed direct builder behavior" {
  let raw = "{\"min_level\":\"warn\",\"target\":\"app.json.same-build\",\"timestamp\":true,\"queue\":{\"max_pending\":2,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}}"
  let application = parse_and_build_application_logger(raw)
  let configured = build_logger(parse_logger_config_text(raw))

  inspect(application.target, content=configured.target)
  inspect(application.timestamp == configured.timestamp, content="true")
  inspect(application.is_enabled(Level::Error) == configured.is_enabled(Level::Error), content="true")
  inspect(application.is_enabled(Level::Info) == configured.is_enabled(Level::Info), content="true")
  let application_sink_kind = match application.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  let configured_sink_kind = match configured.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    RuntimeSink::Console(_) => "Console"
    RuntimeSink::JsonConsole(_) => "JsonConsole"
    RuntimeSink::TextConsole(_) => "TextConsole"
    RuntimeSink::File(_) => "File"
  }
  inspect(application_sink_kind == configured_sink_kind, content="true")

  application.error("one")
  application.error("two")
  application.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(application.pending_count() == configured.pending_count(), content="true")
  inspect(application.dropped_count() == configured.dropped_count(), content="true")
  inspect(application.flush() == configured.flush(), content="true")
  inspect(application.pending_count() == configured.pending_count(), content="true")
}

test "application logger file helpers match direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="app.file.same-build",
    sink=SinkConfig::new(kind=SinkKind::File, path="app-file-same-build.log"),
    queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropOldest)),
  )
  let application = build_application_logger(config)
  let configured = build_logger(config)

  application.error("one")
  application.error("two")
  application.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(application.pending_count() == configured.pending_count(), content="true")
  inspect(application.dropped_count() == configured.dropped_count(), content="true")
  inspect(application.file_available() == configured.file_available(), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(application.file_auto_flush() == configured.file_auto_flush(), content="true")
  inspect(application.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")

  let application_policy = application.file_policy()
  let configured_policy = configured.file_policy()
  inspect(application_policy.append == configured_policy.append, content="true")
  inspect(application_policy.auto_flush == configured_policy.auto_flush, content="true")
  inspect(match application_policy.rotation {
    Some(rotation) => match configured_policy.rotation {
      Some(other) => rotation.max_bytes == other.max_bytes && rotation.max_backups == other.max_backups
      None => false
    }
    None => configured_policy.rotation is None
  }, content="true")

  let application_state = application.file_state()
  let configured_state = configured.file_state()
  inspect(application_state.path == configured_state.path, content="true")
  inspect(application_state.available == configured_state.available, content="true")
  inspect(application_state.append == configured_state.append, content="true")
  inspect(application_state.auto_flush == configured_state.auto_flush, content="true")
  inspect(application_state.open_failures == configured_state.open_failures, content="true")
  inspect(application_state.write_failures == configured_state.write_failures, content="true")
  inspect(application_state.flush_failures == configured_state.flush_failures, content="true")
  inspect(application_state.rotation_failures == configured_state.rotation_failures, content="true")

  match (application.file_runtime_state(), configured.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(application.file_flush() == configured.file_flush(), content="true")
  inspect(application.pending_count() == configured.pending_count(), content="true")
  inspect(application.file_close() == configured.file_close(), content="true")
}

test "application logger file controls match direct configured builder behavior" {
  let config = LoggerConfig::new(
    min_level=Level::Warn,
    target="app.file.controls.same-build",
    sink=SinkConfig::new(kind=SinkKind::File, path="app-file-controls-same-build.log"),
  )
  let application = build_application_logger(config)
  let configured = build_logger(config)

  inspect(application.file_set_append_mode(false) == configured.file_set_append_mode(false), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")

  inspect(application.file_set_auto_flush(false) == configured.file_set_auto_flush(false), content="true")
  inspect(application.file_auto_flush() == configured.file_auto_flush(), content="true")

  let rotation = Some(file_rotation(48, max_backups=3))
  inspect(application.file_set_rotation(rotation) == configured.file_set_rotation(rotation), content="true")
  inspect(application.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")

  let application_policy = application.file_policy()
  let configured_policy = configured.file_policy()
  inspect(application_policy.append == configured_policy.append, content="true")
  inspect(application_policy.auto_flush == configured_policy.auto_flush, content="true")
  inspect(match application_policy.rotation {
    Some(value) => match configured_policy.rotation {
      Some(other) => value.max_bytes == other.max_bytes && value.max_backups == other.max_backups
      None => false
    }
    None => configured_policy.rotation is None
  }, content="true")

  inspect(application.file_reopen_append() == configured.file_reopen_append(), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(application.file_reopen_truncate() == configured.file_reopen_truncate(), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(
    application.file_reopen_with_current_policy() == configured.file_reopen_with_current_policy(),
    content="true",
  )

  inspect(application.file_clear_rotation() == configured.file_clear_rotation(), content="true")
  inspect(application.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")
  inspect(application.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")
  inspect(application.file_reset_policy() == configured.file_reset_policy(), content="true")
  inspect(application.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")
  inspect(application.file_reset_failure_counters() == configured.file_reset_failure_counters(), content="true")

  inspect(application.file_close() == configured.file_close(), content="true")
}

test "parsed application logger keeps direct runtime helper surface" {
  let logger : ApplicationLogger = parse_and_build_application_logger(
    "{\"min_level\":\"warn\",\"target\":\"app.json.helpers\",\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"},\"sink\":{\"kind\":\"file\",\"path\":\"app-json-helpers.log\"}}",
  )

  logger.error("one")
  logger.error("two")
  logger.error("three")
  inspect(logger.pending_count(), content="2")
  inspect(logger.dropped_count(), content="1")
  inspect(logger.file_policy().append, content="true")
  inspect(logger.file_runtime_state() is None, content="false")
  inspect(logger.flush(), content="2")
  inspect(logger.pending_count(), content="0")

  if logger.file_available() {
    inspect(logger.file_flush(), content="true")
    inspect(logger.file_close(), content="true")
  } else {
    inspect(logger.file_flush(), content="false")
    inspect(logger.file_close(), content="false")
  }
}

test "parsed application logger file helpers match parsed configured builder behavior" {
  let raw = "{\"min_level\":\"warn\",\"target\":\"app.json.file.same-build\",\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"},\"sink\":{\"kind\":\"file\",\"path\":\"app-json-file-same-build.log\"}}"
  let application = parse_and_build_application_logger(raw)
  let configured = parse_and_build_logger(raw)

  application.error("one")
  application.error("two")
  application.error("three")
  configured.error("one")
  configured.error("two")
  configured.error("three")

  inspect(application.pending_count() == configured.pending_count(), content="true")
  inspect(application.dropped_count() == configured.dropped_count(), content="true")
  inspect(application.file_available() == configured.file_available(), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(application.file_auto_flush() == configured.file_auto_flush(), content="true")
  inspect(application.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")

  let application_state = application.file_state()
  let configured_state = configured.file_state()
  inspect(application_state.path == configured_state.path, content="true")
  inspect(application_state.available == configured_state.available, content="true")
  inspect(application_state.append == configured_state.append, content="true")
  inspect(application_state.auto_flush == configured_state.auto_flush, content="true")
  inspect(application_state.open_failures == configured_state.open_failures, content="true")
  inspect(application_state.write_failures == configured_state.write_failures, content="true")
  inspect(application_state.flush_failures == configured_state.flush_failures, content="true")
  inspect(application_state.rotation_failures == configured_state.rotation_failures, content="true")

  match (application.file_runtime_state(), configured.file_runtime_state()) {
    (Some(snapshot), Some(other)) => {
      inspect(snapshot.file.path == other.file.path, content="true")
      inspect(snapshot.file.available == other.file.available, content="true")
      inspect(snapshot.queued == other.queued, content="true")
      inspect(snapshot.pending_count == other.pending_count, content="true")
      inspect(snapshot.dropped_count == other.dropped_count, content="true")
    }
    _ => inspect(false, content="true")
  }

  inspect(application.file_flush() == configured.file_flush(), content="true")
  inspect(application.pending_count() == configured.pending_count(), content="true")
  inspect(application.file_close() == configured.file_close(), content="true")
}

test "parsed application logger file controls match parsed configured builder behavior" {
  let raw = "{\"min_level\":\"warn\",\"target\":\"app.json.file.controls.same-build\",\"sink\":{\"kind\":\"file\",\"path\":\"app-json-file-controls-same-build.log\"}}"
  let application = parse_and_build_application_logger(raw)
  let configured = parse_and_build_logger(raw)

  inspect(application.file_set_append_mode(false) == configured.file_set_append_mode(false), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(application.file_set_auto_flush(false) == configured.file_set_auto_flush(false), content="true")
  inspect(application.file_auto_flush() == configured.file_auto_flush(), content="true")

  let rotation = Some(file_rotation(40, max_backups=2))
  inspect(application.file_set_rotation(rotation) == configured.file_set_rotation(rotation), content="true")
  inspect(application.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")
  inspect(application.file_reopen(append=Some(false)) == configured.file_reopen(append=Some(false)), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(application.file_reopen_append() == configured.file_reopen_append(), content="true")
  inspect(application.file_append_mode() == configured.file_append_mode(), content="true")
  inspect(application.file_clear_rotation() == configured.file_clear_rotation(), content="true")
  inspect(application.file_rotation_enabled() == configured.file_rotation_enabled(), content="true")
  inspect(application.file_reset_policy() == configured.file_reset_policy(), content="true")
  inspect(application.file_policy_matches_default() == configured.file_policy_matches_default(), content="true")
  inspect(application.file_reset_failure_counters() == configured.file_reset_failure_counters(), content="true")

  inspect(application.file_close() == configured.file_close(), content="true")
}

test "parsed configured logger keeps composition and runtime helper surface" {
  let logger : ConfiguredLogger = parse_and_build_logger(
    "{\"min_level\":\"warn\",\"target\":\"parsed.compose\",\"timestamp\":true,\"queue\":{\"max_pending\":2,\"overflow\":\"DropNewest\"},\"sink\":{\"kind\":\"console\"}}",
  )
  let derived = logger.child("worker")

  inspect(derived.target, content="parsed.compose.worker")
  inspect(derived.timestamp, content="true")
  inspect(derived.is_enabled(Level::Error), content="true")
  inspect(derived.is_enabled(Level::Info), content="false")
  inspect(match derived.sink {
    RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    RuntimeSink::QueuedFile(_) => "QueuedFile"
    _ => "Other"
  }, content="QueuedConsole")

  derived.error("one")
  derived.error("two")
  inspect(derived.pending_count(), content="2")
  inspect(derived.dropped_count(), content="0")
  inspect(derived.flush(), content="2")
  inspect(derived.pending_count(), content="0")
}

test "parsed configured logger log supports per-call target override" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = parse_and_build_logger(
    "{\"min_level\":\"warn\",\"target\":\"parsed.default\",\"sink\":{\"kind\":\"console\"}}",
  )
    .with_patch(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.log(
    Level::Error,
    "override",
    fields=[field("mode", "test")],
    target="parsed.override",
  )
  inspect(captured_target.val, content="parsed.override")
  inspect(captured_message.val, content="override")
  inspect(captured_fields.val.length(), content="2")
  inspect(captured_fields.val[0].key, content="service")
  inspect(captured_fields.val[0].value, content="bitlogger")
  inspect(captured_fields.val[1].key, content="mode")
  inspect(captured_fields.val[1].value, content="test")

  logger.log(Level::Error, "default")
  inspect(captured_target.val, content="parsed.default")
  inspect(captured_message.val, content="default")
  inspect(captured_fields.val.length(), content="1")
  inspect(captured_fields.val[0].key, content="service")
}

test "parsed configured logger severity helpers use stored target without override" {
  let captured_levels : Ref[Array[String]] = Ref([])
  let captured_targets : Ref[Array[String]] = Ref([])
  let captured_fields : Ref[Array[Array[Field]]] = Ref([])
  let logger = parse_and_build_logger(
    "{\"min_level\":\"info\",\"target\":\"parsed.helpers\",\"sink\":{\"kind\":\"console\"}}",
  )
    .with_patch(fn(rec) {
      captured_levels.val.push(rec.level.label())
      captured_targets.val.push(rec.target)
      captured_fields.val.push(rec.fields)
      rec
    })
    .with_context_fields([field("service", "bitlogger")])

  logger.info("info", fields=[field("mode", "info")])
  logger.warn("warn", fields=[field("mode", "warn")])
  logger.error("error", fields=[field("mode", "error")])

  inspect(captured_levels.val.length(), content="3")
  inspect(captured_levels.val[0], content="INFO")
  inspect(captured_levels.val[1], content="WARN")
  inspect(captured_levels.val[2], content="ERROR")
  inspect(captured_targets.val.length(), content="3")
  inspect(captured_targets.val[0], content="parsed.helpers")
  inspect(captured_targets.val[1], content="parsed.helpers")
  inspect(captured_targets.val[2], content="parsed.helpers")
  inspect(captured_fields.val[0].length(), content="2")
  inspect(captured_fields.val[1].length(), content="2")
  inspect(captured_fields.val[2].length(), content="2")
  inspect(captured_fields.val[0][0].key, content="service")
  inspect(captured_fields.val[0][1].value, content="info")
  inspect(captured_fields.val[1][0].key, content="service")
  inspect(captured_fields.val[1][1].value, content="warn")
  inspect(captured_fields.val[2][0].key, content="service")
  inspect(captured_fields.val[2][1].value, content="error")
}

test "sync parse-build facades forward config errors" {
  let raw = "{\"sink\":{\"kind\":\"file\",\"path\":\"\"}}"
  let malformed = "{"

  let configured_error = (fn() -> String raise ConfigError {
    ignore(parse_and_build_logger(raw))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(configured_error, content="File sink requires non-empty path")

  let application_error = (fn() -> String raise ConfigError {
    ignore(parse_and_build_application_logger(raw))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(application_error, content="File sink requires non-empty path")

  let library_error = (fn() -> String raise ConfigError {
    ignore(parse_and_build_library_logger(raw))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(library_error, content="File sink requires non-empty path")

  let configured_invalid_json = (fn() -> String raise ConfigError {
    ignore(parse_and_build_logger(malformed))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(configured_invalid_json.contains("Invalid JSON:"), content="true")

  let application_invalid_json = (fn() -> String raise ConfigError {
    ignore(parse_and_build_application_logger(malformed))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(application_invalid_json.contains("Invalid JSON:"), content="true")

  let library_invalid_json = (fn() -> String raise ConfigError {
    ignore(parse_and_build_library_logger(malformed))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(library_invalid_json.contains("Invalid JSON:"), content="true")
}
