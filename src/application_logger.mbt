///|
pub type ApplicationLogger = ConfiguredLogger

///|
pub fn build_application_logger(config : LoggerConfig) -> ApplicationLogger {
  build_logger(config)
}

///|
pub fn parse_and_build_application_logger(
  input : String,
) -> ApplicationLogger raise ConfigError {
  parse_and_build_logger(input)
}
