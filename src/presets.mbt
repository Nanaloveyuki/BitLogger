pub fn console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
) -> LoggerConfig {
  LoggerConfig::new(
    min_level=min_level,
    target=target,
    timestamp=timestamp,
    sink=SinkConfig::new(kind=SinkKind::Console),
  )
}

pub fn json_console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
) -> LoggerConfig {
  LoggerConfig::new(
    min_level=min_level,
    target=target,
    timestamp=timestamp,
    sink=SinkConfig::new(kind=SinkKind::JsonConsole),
  )
}

pub fn text_console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig {
  LoggerConfig::new(
    min_level=min_level,
    target=target,
    timestamp=timestamp,
    sink=SinkConfig::new(kind=SinkKind::TextConsole, text_formatter=text_formatter),
  )
}

pub fn file(
  path : String,
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig raise ConfigError {
  if path == "" {
    raise ConfigError::InvalidConfig("File sink requires non-empty path")
  }
  LoggerConfig::new(
    min_level=min_level,
    target=target,
    timestamp=timestamp,
    sink=SinkConfig::new(
      kind=SinkKind::File,
      path=path,
      append=append,
      auto_flush=auto_flush,
      rotation=rotation,
      text_formatter=text_formatter,
    ),
  )
}

pub fn with_queue(
  config : LoggerConfig,
  max_pending~ : Int = 0,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> LoggerConfig {
  LoggerConfig::new(
    min_level=config.min_level,
    target=config.target,
    timestamp=config.timestamp,
    sink=config.sink,
    queue=Some(QueueConfig::new(max_pending, overflow=overflow)),
  )
}

pub fn with_file_rotation(
  config : LoggerConfig,
  max_bytes : Int,
  max_backups~ : Int = 1,
) -> LoggerConfig {
  match config.sink.kind {
    SinkKind::File =>
      LoggerConfig::new(
        min_level=config.min_level,
        target=config.target,
        timestamp=config.timestamp,
        sink=SinkConfig::new(
          kind=config.sink.kind,
          path=config.sink.path,
          append=config.sink.append,
          auto_flush=config.sink.auto_flush,
          rotation=Some(file_rotation(max_bytes, max_backups=max_backups)),
          text_formatter=config.sink.text_formatter,
        ),
        queue=config.queue,
      )
    _ => config
  }
}
