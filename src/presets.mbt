///|
pub fn console(
  min_level? : Level = Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
) -> LoggerConfig {
  @presets_pkg.console(min_level~, target~, timestamp~)
}

///|
pub fn json_console(
  min_level? : Level = Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
) -> LoggerConfig {
  @presets_pkg.json_console(min_level~, target~, timestamp~)
}

///|
pub fn text_console(
  min_level? : Level = Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
  text_formatter? : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig {
  @presets_pkg.text_console(min_level~, target~, timestamp~, text_formatter~)
}

///|
pub fn file(
  path : String,
  min_level? : Level = Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
  append? : Bool = true,
  auto_flush? : Bool = true,
  rotation? : FileRotation? = None,
  text_formatter? : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig raise ConfigError {
  @presets_pkg.file(
    path,
    min_level~,
    target~,
    timestamp~,
    append~,
    auto_flush~,
    rotation~,
    text_formatter~,
  )
}

///|
pub fn with_queue(
  config : LoggerConfig,
  max_pending? : Int = 0,
  overflow? : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> LoggerConfig {
  @presets_pkg.with_queue(config, max_pending~, overflow~)
}

///|
pub fn with_file_rotation(
  config : LoggerConfig,
  max_bytes : Int,
  max_backups? : Int = 1,
) -> LoggerConfig {
  @presets_pkg.with_file_rotation(config, max_bytes, max_backups~)
}

///|
pub fn with_file_rotation_i64(
  config : LoggerConfig,
  max_bytes : Int64,
  max_backups? : Int = 1,
) -> LoggerConfig {
  @presets_pkg.with_file_rotation_i64(config, max_bytes, max_backups~)
}
