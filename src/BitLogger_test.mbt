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

test "file state json helpers stringify stable snapshots" {
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
  inspect(
    @json_parser.stringify(plain),
    content="{\"path\":\"demo.log\",\"available\":true,\"append\":false,\"auto_flush\":true,\"open_failures\":1,\"write_failures\":2,\"flush_failures\":3,\"rotation_failures\":4,\"rotation\":{\"max_bytes\":64,\"max_backups\":2}}",
  )
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
  inspect(
    @json_parser.stringify(
      file_sink_policy_to_json(
        FileSinkPolicy::new(
          append=false,
          auto_flush=true,
          rotation=Some(file_rotation(96, max_backups=3)),
        ),
      ),
    ),
    content="{\"append\":false,\"auto_flush\":true,\"rotation\":{\"max_bytes\":96,\"max_backups\":3}}",
  )
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

test "library logger can be parsed and built from config text" {
  let logger = parse_and_build_library_logger(
    "{\"min_level\":\"warn\",\"target\":\"lib.json\",\"sink\":{\"kind\":\"console\"}}",
  )
  let full = logger.to_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(full.target, content="lib.json")
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

test "default library logger mirrors shared sync defaults" {
  set_default_min_level(Level::Warn)
  set_default_target("lib.default")
  let logger = default_library_logger()
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.to_logger().target, content="lib.default")
}

test "application logger aliases configured runtime entry" {
  let logger = build_application_logger(
    LoggerConfig::new(min_level=Level::Warn, target="app.runtime"),
  )
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.target, content="app.runtime")
}

test "application logger can be built from config text" {
  let logger = parse_and_build_application_logger(
    "{\"min_level\":\"warn\",\"target\":\"app.json\",\"sink\":{\"kind\":\"console\"}}",
  )
  inspect(logger.is_enabled(Level::Error), content="true")
  inspect(logger.is_enabled(Level::Info), content="false")
  inspect(logger.target, content="app.json")
}
