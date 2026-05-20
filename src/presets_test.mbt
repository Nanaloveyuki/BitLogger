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

test "file preset preserves empty path as configured" {
  let config = file("")
  inspect(match config.sink.kind {
    SinkKind::File => "File"
    _ => "other"
  }, content="File")
  inspect(config.sink.path, content="")
  inspect(config.sink.rotation is None, content="true")
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
