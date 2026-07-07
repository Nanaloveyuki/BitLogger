///|
test "logger config parser reads core options" {
  let config = parse_logger_config_text(
    "{\"min_level\":\"debug\",\"target\":\"service\",\"timestamp\":true}",
  )
  inspect(config.min_level.label(), content="DEBUG")
  inspect(config.target, content="service")
  inspect(config.timestamp, content="true")
}

///|
test "logger config parser reads formatter and queue options" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"separator\":\" | \",\"show_timestamp\":false,\"template\":\"[{level}] {message}\",\"color_mode\":\"always\"}},\"queue\":{\"max_pending\":32,\"overflow\":\"DropOldest\"}}",
  )
  inspect(
    match config.sink.kind {
      SinkKind::TextConsole => "TextConsole"
      _ => "other"
    },
    content="TextConsole",
  )
  inspect(config.sink.text_formatter.separator, content=" | ")
  inspect(config.sink.text_formatter.show_timestamp, content="false")
  inspect(config.sink.text_formatter.template, content="[{level}] {message}")
  inspect(
    color_mode_label(config.sink.text_formatter.color_mode),
    content="always",
  )
  match config.queue {
    Some(queue) => {
      inspect(queue.max_pending, content="32")
      inspect(
        match queue.overflow {
          QueueOverflowPolicy::DropNewest => "DropNewest"
          QueueOverflowPolicy::DropOldest => "DropOldest"
        },
        content="DropOldest",
      )
    }
    None => inspect(false, content="true")
  }
}

///|
test "logger config parser reads file rotation options" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"file\",\"path\":\"bitlogger.log\",\"rotation\":{\"max_bytes\":128,\"max_backups\":3}}}",
  )
  inspect(
    match config.sink.kind {
      SinkKind::File => "File"
      _ => "other"
    },
    content="File",
  )
  inspect(config.sink.path, content="bitlogger.log")
  match config.sink.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="128")
      inspect(rotation.max_backups, content="3")
      inspect(rotation.native_wide_max_bytes is None, content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "logger config parser prefers max_bytes_i64 when present" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"file\",\"path\":\"bitlogger.log\",\"rotation\":{\"max_bytes\":128,\"max_bytes_i64\":\"4294967296\",\"max_backups\":3}}}",
  )
  inspect(config.sink.path, content="bitlogger.log")
  match config.sink.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="2147483647")
      inspect(rotation.max_backups, content="3")
      inspect(rotation.native_wide_max_bytes.unwrap(), content="4294967296")
    }
    None => inspect(false, content="true")
  }
}

///|
test "logger config parser fills omitted top-level keys from defaults" {
  let config = parse_logger_config_text("{}")
  inspect(config.min_level.label(), content="INFO")
  inspect(config.target, content="")
  inspect(config.timestamp, content="false")
  inspect(config.queue is None, content="true")
  inspect(
    match config.sink.kind {
      SinkKind::Console => "Console"
      SinkKind::JsonConsole => "JsonConsole"
      SinkKind::TextConsole => "TextConsole"
      SinkKind::File => "File"
    },
    content="Console",
  )
  inspect(config.sink.path, content="")
  inspect(config.sink.append, content="true")
  inspect(config.sink.auto_flush, content="true")
  inspect(config.sink.rotation is None, content="true")
  inspect(config.sink.text_formatter.show_timestamp, content="true")
  inspect(config.sink.text_formatter.separator, content=" ")
  inspect(config.sink.text_formatter.field_separator, content=" ")
  inspect(config.sink.text_formatter.template, content="")
}

///|
test "logger config parser fills nested queue and formatter defaults" {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"separator\":\" | \"}},\"queue\":{\"max_pending\":4}}",
  )
  inspect(
    match config.sink.kind {
      SinkKind::Console => "Console"
      SinkKind::JsonConsole => "JsonConsole"
      SinkKind::TextConsole => "TextConsole"
      SinkKind::File => "File"
    },
    content="TextConsole",
  )
  inspect(config.sink.text_formatter.show_timestamp, content="true")
  inspect(config.sink.text_formatter.show_level, content="true")
  inspect(config.sink.text_formatter.show_target, content="true")
  inspect(config.sink.text_formatter.show_fields, content="true")
  inspect(config.sink.text_formatter.separator, content=" | ")
  inspect(config.sink.text_formatter.field_separator, content=" ")
  inspect(config.sink.text_formatter.template, content="")
  inspect(
    color_mode_label(config.sink.text_formatter.color_mode),
    content="never",
  )
  inspect(
    color_support_label(config.sink.text_formatter.color_support),
    content="truecolor",
  )
  inspect(
    style_markup_mode_label(config.sink.text_formatter.style_markup),
    content="full",
  )
  inspect(
    style_markup_mode_label(config.sink.text_formatter.target_style_markup),
    content="disabled",
  )
  inspect(
    style_markup_mode_label(config.sink.text_formatter.fields_style_markup),
    content="disabled",
  )
  inspect(config.sink.text_formatter.style_tags.length(), content="0")
  match config.queue {
    Some(queue) => {
      inspect(queue.max_pending, content="4")
      inspect(
        match queue.overflow {
          QueueOverflowPolicy::DropNewest => "DropNewest"
          QueueOverflowPolicy::DropOldest => "DropOldest"
        },
        content="DropNewest",
      )
    }
    None => inspect(false, content="true")
  }
}

///|
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
    ignore(
      parse_logger_config_text(
        "{\"sink\":{\"kind\":\"console\",\"text_formatter\":{\"color_mode\":\"loud\"}}}",
      ),
    )
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(invalid_enum_error, content="Unsupported color mode: loud")
}

///|
