///|
pub type ApplicationAsyncLogger = AsyncLogger[@bitlogger.RuntimeSink]

///|
pub type ApplicationTextAsyncLogger = AsyncLogger[
  @bitlogger.FormattedConsoleSink,
]

///|
pub fn build_application_async_logger(
  config : AsyncLoggerBuildConfig,
) -> ApplicationAsyncLogger {
  build_async_logger(config)
}

///|
pub fn build_application_text_async_logger(
  config : AsyncLoggerBuildConfig,
) -> ApplicationTextAsyncLogger {
  build_async_text_logger(config)
}

///|
pub fn parse_and_build_application_async_logger(
  input : String,
) -> ApplicationAsyncLogger raise {
  build_application_async_logger(parse_async_logger_build_config_text(input))
}
