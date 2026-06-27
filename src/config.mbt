///|
pub type ConfigError = @utils.ConfigError

///|
pub type SinkKind = @utils.SinkKind

///|
pub type TextFormatterConfig = @utils.TextFormatterConfig

///|
pub type QueueConfig = @utils.QueueConfig

///|
pub type SinkConfig = @utils.SinkConfig

///|
pub type LoggerConfig = @utils.LoggerConfig

///|
pub fn default_text_formatter_config() -> TextFormatterConfig {
  @utils.default_text_formatter_config()
}

///|
pub fn default_sink_config() -> SinkConfig {
  @utils.default_sink_config()
}

///|
pub fn default_logger_config() -> LoggerConfig {
  @utils.default_logger_config()
}

///|
pub fn parse_logger_config_text(
  input : String,
) -> LoggerConfig raise ConfigError {
  @utils.parse_logger_config_text(input)
}

///|
pub fn queue_config_to_json(queue : QueueConfig) -> @json_parser.JsonValue {
  @utils.queue_config_to_json(queue)
}

///|
pub fn stringify_queue_config(
  queue : QueueConfig,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_queue_config(queue, pretty~)
}

///|
pub fn text_formatter_config_to_json(
  config : TextFormatterConfig,
) -> @json_parser.JsonValue {
  @utils.text_formatter_config_to_json(config)
}

///|
pub fn stringify_text_formatter_config(
  config : TextFormatterConfig,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_text_formatter_config(config, pretty~)
}

///|
pub fn file_rotation_config_to_json(
  config : FileRotation,
) -> @json_parser.JsonValue {
  @utils.file_rotation_config_to_json(config)
}

///|
pub fn sink_config_to_json(config : SinkConfig) -> @json_parser.JsonValue {
  @utils.sink_config_to_json(config)
}

///|
pub fn stringify_sink_config(
  config : SinkConfig,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_sink_config(config, pretty~)
}

///|
pub fn logger_config_to_json(config : LoggerConfig) -> @json_parser.JsonValue {
  @utils.logger_config_to_json(config)
}

///|
pub fn stringify_logger_config(
  config : LoggerConfig,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_logger_config(config, pretty~)
}
