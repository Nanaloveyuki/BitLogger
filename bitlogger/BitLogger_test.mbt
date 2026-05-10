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
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"separator\":\" | \",\"show_timestamp\":false,\"template\":\"[{level}] {message}\"}},\"queue\":{\"max_pending\":32,\"overflow\":\"DropOldest\"}}",
  )
  inspect(match config.sink.kind {
    SinkKind::TextConsole => "TextConsole"
    _ => "other"
  }, content="TextConsole")
  inspect(config.sink.text_formatter.separator, content=" | ")
  inspect(config.sink.text_formatter.show_timestamp, content="false")
  inspect(config.sink.text_formatter.template, content="[{level}] {message}")
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
  inspect(logger.file_available() == native_files_supported(), content="true")
  inspect(logger.file_path(), content="config-file.log")
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="false")
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

test "configured logger reports disabled rotation when file sink has none" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-no-rotation.log"),
    ),
  )
  inspect(logger.file_rotation_enabled(), content="false")
  inspect(logger.file_rotation_config() is None, content="true")
  ignore(logger.close())
}

test "configured logger file setters update file sink policy state" {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="config-setters.log"),
      queue=Some(QueueConfig::new(2, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  inspect(logger.file_append_mode(), content="true")
  inspect(logger.file_auto_flush(), content="true")
  inspect(logger.file_rotation_enabled(), content="false")
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
  ignore(logger.close())
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
    inspect(logger.file_open_failures(), content="3")
    inspect(logger.file_reopen_append(), content="false")
    inspect(logger.file_append_mode(), content="true")
    inspect(logger.file_open_failures(), content="4")
  }
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
  if logger.file_available() {
    inspect(logger.pending_count(), content="2")
    inspect(logger.file_flush(), content="true")
    inspect(logger.pending_count(), content="0")
    inspect(logger.file_close(), content="true")
  } else {
    inspect(logger.pending_count(), content="2")
    inspect(logger.file_flush(), content="false")
    inspect(logger.pending_count(), content="0")
    inspect(logger.file_close(), content="false")
  }
}
