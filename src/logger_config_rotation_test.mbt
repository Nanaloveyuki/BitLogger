///|
test "logger config parser reads formatter style tags" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"color_mode\":\"always\",\"color_support\":\"basic\",\"style_markup\":\"builtin\",\"target_style_markup\":\"builtin\",\"fields_style_markup\":\"disabled\",\"style_tags\":{\"accent\":{\"fg\":\"#4cc9f0\",\"bold\":true},\"panel\":{\"bg\":\"#202020\",\"underline\":true}}}}}",
  )
  inspect(
    style_markup_mode_label(config.sink.text_formatter.style_markup),
    content="builtin",
  )
  inspect(
    color_support_label(config.sink.text_formatter.color_support),
    content="basic",
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

///|
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
      inspect(rotation.native_wide_max_bytes is None, content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "logger config stringify roundtrips file rotation i64 metadata" {
  let text = stringify_logger_config(
    LoggerConfig::new(
      sink=SinkConfig::new(
        kind=SinkKind::File,
        path="bitlogger.log",
        rotation=Some(file_rotation_i64(4294967296L, max_backups=2)),
      ),
    ),
  )
  let config = parse_logger_config_text(text)
  inspect(config.sink.path, content="bitlogger.log")
  match config.sink.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="2147483647")
      inspect(rotation.max_backups, content="2")
      inspect(rotation.native_wide_max_bytes.unwrap(), content="4294967296")
    }
    None => inspect(false, content="true")
  }
}

///|
