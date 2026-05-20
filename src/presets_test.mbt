test "logger config presets use expected defaults" {
  let console_config = console()
  inspect(console_config.min_level.label(), content="INFO")
  inspect(console_config.target, content="")
  inspect(console_config.timestamp, content="false")
  inspect(match console_config.sink.kind {
    SinkKind::Console => "Console"
    _ => "other"
  }, content="Console")
  inspect(console_config.queue is None, content="true")

  let json_config = json_console()
  inspect(match json_config.sink.kind {
    SinkKind::JsonConsole => "JsonConsole"
    _ => "other"
  }, content="JsonConsole")
  inspect(json_config.queue is None, content="true")

  let text_config = text_console()
  inspect(match text_config.sink.kind {
    SinkKind::TextConsole => "TextConsole"
    _ => "other"
  }, content="TextConsole")
  inspect(text_config.sink.text_formatter.show_timestamp, content="true")
  inspect(color_mode_label(text_config.sink.text_formatter.color_mode), content="never")
}

test "file preset uses file sink defaults" {
  let config = file("bitlogger.log")
  inspect(config.min_level.label(), content="INFO")
  inspect(config.target, content="")
  inspect(config.timestamp, content="false")
  inspect(match config.sink.kind {
    SinkKind::File => "File"
    _ => "other"
  }, content="File")
  inspect(config.sink.path, content="bitlogger.log")
  inspect(config.sink.append, content="true")
  inspect(config.sink.auto_flush, content="true")
  inspect(config.sink.rotation is None, content="true")
  inspect(config.queue is None, content="true")
}

test "file preset rejects empty path like parser file sink config" {
  let preset_error = (fn() -> String raise ConfigError {
    ignore(file(""))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(preset_error, content="File sink requires non-empty path")

  let parser_error = (fn() -> String raise ConfigError {
    ignore(parse_logger_config_text("{\"sink\":{\"kind\":\"file\",\"path\":\"\"}}"))
    "no error"
  })() catch {
    ConfigError::InvalidConfig(message) => message
  }
  inspect(parser_error, content="File sink requires non-empty path")
}

test "preset helpers compose queue and file rotation without losing config" {
  let formatter = TextFormatterConfig::new(show_timestamp=false, separator=" | ")
  let config = file(
    "service.log",
    min_level=Level::Warn,
    target="svc.worker",
    timestamp=true,
    append=false,
    auto_flush=false,
    text_formatter=formatter,
  )
  let config = with_file_rotation(
    with_queue(config, max_pending=32, overflow=QueueOverflowPolicy::DropOldest),
    128,
    max_backups=3,
  )
  inspect(config.min_level.label(), content="WARN")
  inspect(config.target, content="svc.worker")
  inspect(config.timestamp, content="true")
  inspect(config.sink.path, content="service.log")
  inspect(config.sink.append, content="false")
  inspect(config.sink.auto_flush, content="false")
  inspect(config.sink.text_formatter.show_timestamp, content="false")
  inspect(config.sink.text_formatter.separator, content=" | ")
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
  match config.sink.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="128")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
}

test "queue helper preserves file rotation when applied after rotation" {
  let config = with_queue(
    with_file_rotation(file("service.log", append=false), 256, max_backups=2),
    max_pending=8,
    overflow=QueueOverflowPolicy::DropNewest,
  )
  inspect(config.sink.path, content="service.log")
  inspect(config.sink.append, content="false")
  match config.queue {
    Some(queue) => {
      inspect(queue.max_pending, content="8")
      inspect(match queue.overflow {
        QueueOverflowPolicy::DropNewest => "DropNewest"
        QueueOverflowPolicy::DropOldest => "DropOldest"
      }, content="DropNewest")
    }
    None => inspect(false, content="true")
  }
  match config.sink.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="256")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
}

test "file rotation helper leaves non-file presets unchanged" {
  let console_config = with_file_rotation(console(target="console"), 64, max_backups=2)
  inspect(match console_config.sink.kind {
    SinkKind::Console => "Console"
    _ => "other"
  }, content="Console")
  inspect(console_config.target, content="console")
  inspect(console_config.sink.rotation is None, content="true")

  let text_config = with_file_rotation(
    text_console(target="text", text_formatter=TextFormatterConfig::new(separator=" :: ")),
    96,
    max_backups=4,
  )
  inspect(match text_config.sink.kind {
    SinkKind::TextConsole => "TextConsole"
    _ => "other"
  }, content="TextConsole")
  inspect(text_config.target, content="text")
  inspect(text_config.sink.text_formatter.separator, content=" :: ")
  inspect(text_config.sink.rotation is None, content="true")
}

test "file rotation helper keeps queued non-file presets unchanged" {
  let config = with_queue(
    json_console(min_level=Level::Error, target="json"),
    max_pending=4,
    overflow=QueueOverflowPolicy::DropOldest,
  )
  let rotated = with_file_rotation(config, 512, max_backups=5)
  inspect(rotated.min_level.label(), content="ERROR")
  inspect(rotated.target, content="json")
  inspect(match rotated.sink.kind {
    SinkKind::JsonConsole => "JsonConsole"
    _ => "other"
  }, content="JsonConsole")
  inspect(rotated.sink.rotation is None, content="true")
  match rotated.queue {
    Some(queue) => {
      inspect(queue.max_pending, content="4")
      inspect(match queue.overflow {
        QueueOverflowPolicy::DropNewest => "DropNewest"
        QueueOverflowPolicy::DropOldest => "DropOldest"
      }, content="DropOldest")
    }
    None => inspect(false, content="true")
  }
}
