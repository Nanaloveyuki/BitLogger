///|
pub fn console(
  min_level? : @core.Level = @core.Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
) -> @config_model.LoggerConfig {
  @config_model.LoggerConfig::new(
    min_level~,
    target~,
    timestamp~,
    sink=@config_model.SinkConfig::new(kind=@config_model.SinkKind::Console),
  )
}

///|
pub fn json_console(
  min_level? : @core.Level = @core.Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
) -> @config_model.LoggerConfig {
  @config_model.LoggerConfig::new(
    min_level~,
    target~,
    timestamp~,
    sink=@config_model.SinkConfig::new(kind=@config_model.SinkKind::JsonConsole),
  )
}

///|
pub fn text_console(
  min_level? : @core.Level = @core.Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
  text_formatter? : @config_model.TextFormatterConfig = @config_model.default_text_formatter_config(),
) -> @config_model.LoggerConfig {
  @config_model.LoggerConfig::new(
    min_level~,
    target~,
    timestamp~,
    sink=@config_model.SinkConfig::new(
      kind=@config_model.SinkKind::TextConsole,
      text_formatter~,
    ),
  )
}

///|
pub fn file(
  path : String,
  min_level? : @core.Level = @core.Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
  append? : Bool = true,
  auto_flush? : Bool = true,
  rotation? : @file_model.FileRotation? = None,
  text_formatter? : @config_model.TextFormatterConfig = @config_model.default_text_formatter_config(),
) -> @config_model.LoggerConfig raise @config_model.ConfigError {
  if path == "" {
    raise @config_model.ConfigError::InvalidConfig(
      "File sink requires non-empty path",
    )
  }
  @config_model.LoggerConfig::new(
    min_level~,
    target~,
    timestamp~,
    sink=@config_model.SinkConfig::new(
      kind=@config_model.SinkKind::File,
      path~,
      append~,
      auto_flush~,
      rotation~,
      text_formatter~,
    ),
  )
}

///|
pub fn with_queue(
  config : @config_model.LoggerConfig,
  max_pending? : Int = 0,
  overflow? : @queue_model.QueueOverflowPolicy = @queue_model.QueueOverflowPolicy::DropNewest,
) -> @config_model.LoggerConfig {
  @config_model.LoggerConfig::new(
    min_level=config.min_level,
    target=config.target,
    timestamp=config.timestamp,
    sink=config.sink,
    queue=Some(@config_model.QueueConfig::new(max_pending, overflow~)),
  )
}

///|
pub fn with_file_rotation(
  config : @config_model.LoggerConfig,
  max_bytes : Int,
  max_backups? : Int = 1,
) -> @config_model.LoggerConfig {
  match config.sink.kind {
    @config_model.SinkKind::File =>
      @config_model.LoggerConfig::new(
        min_level=config.min_level,
        target=config.target,
        timestamp=config.timestamp,
        sink=@config_model.SinkConfig::new(
          kind=config.sink.kind,
          path=config.sink.path,
          append=config.sink.append,
          auto_flush=config.sink.auto_flush,
          rotation=Some(@file_model.file_rotation(max_bytes, max_backups~)),
          text_formatter=config.sink.text_formatter,
        ),
        queue=config.queue,
      )
    _ => config
  }
}

///|
pub fn with_file_rotation_i64(
  config : @config_model.LoggerConfig,
  max_bytes : Int64,
  max_backups? : Int = 1,
) -> @config_model.LoggerConfig {
  match config.sink.kind {
    @config_model.SinkKind::File =>
      @config_model.LoggerConfig::new(
        min_level=config.min_level,
        target=config.target,
        timestamp=config.timestamp,
        sink=@config_model.SinkConfig::new(
          kind=config.sink.kind,
          path=config.sink.path,
          append=config.sink.append,
          auto_flush=config.sink.auto_flush,
          rotation=Some(@file_model.file_rotation_i64(max_bytes, max_backups~)),
          text_formatter=config.sink.text_formatter,
        ),
        queue=config.queue,
      )
    _ => config
  }
}
