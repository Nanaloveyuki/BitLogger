///|
pub type ConfigError = @config_model.ConfigError

///|
pub type SinkKind = @config_model.SinkKind

///|
pub type TextFormatterConfig = @config_model.TextFormatterConfig

///|
pub type QueueConfig = @config_model.QueueConfig

///|
pub type SinkConfig = @config_model.SinkConfig

///|
pub type LoggerConfig = @config_model.LoggerConfig

///|
pub fn default_text_formatter_config() -> TextFormatterConfig {
  @config_model.default_text_formatter_config()
}

///|
pub fn default_sink_config() -> SinkConfig {
  @config_model.default_sink_config()
}

///|
pub fn default_logger_config() -> LoggerConfig {
  @config_model.default_logger_config()
}

///|
pub fn parse_logger_config_text(
  input : String,
) -> LoggerConfig raise ConfigError {
  @config_model.parse_logger_config_text(input)
}

///|
pub fn queue_config_to_json(queue : QueueConfig) -> @json_parser.JsonValue {
  @config_model.queue_config_to_json(queue)
}

///|
pub fn stringify_queue_config(
  queue : QueueConfig,
  pretty? : Bool = false,
) -> String {
  @config_model.stringify_queue_config(queue, pretty~)
}

///|
pub fn text_formatter_config_to_json(
  config : TextFormatterConfig,
) -> @json_parser.JsonValue {
  @config_model.text_formatter_config_to_json(config)
}

///|
pub fn stringify_text_formatter_config(
  config : TextFormatterConfig,
  pretty? : Bool = false,
) -> String {
  @config_model.stringify_text_formatter_config(config, pretty~)
}

///|
pub fn file_rotation_config_to_json(
  config : FileRotation,
) -> @json_parser.JsonValue {
  @file_model.file_rotation_config_to_json(config)
}

///|
pub fn sink_config_to_json(config : SinkConfig) -> @json_parser.JsonValue {
  @config_model.sink_config_to_json(config)
}

///|
pub fn stringify_sink_config(
  config : SinkConfig,
  pretty? : Bool = false,
) -> String {
  @config_model.stringify_sink_config(config, pretty~)
}

///|
pub fn logger_config_to_json(config : LoggerConfig) -> @json_parser.JsonValue {
  @config_model.logger_config_to_json(config)
}

///|
pub fn stringify_logger_config(
  config : LoggerConfig,
  pretty? : Bool = false,
) -> String {
  @config_model.stringify_logger_config(config, pretty~)
}
