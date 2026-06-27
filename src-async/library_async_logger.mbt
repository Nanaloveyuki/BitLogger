///|
pub struct LibraryAsyncLogger[S] {
  inner : AsyncLogger[S]
}

///|
fn[S] library_async_logger(logger : AsyncLogger[S]) -> LibraryAsyncLogger[S] {
  { inner: logger }
}

///|
pub fn[S] AsyncLogger::to_library_async_logger(
  self : AsyncLogger[S],
) -> LibraryAsyncLogger[S] {
  library_async_logger(self)
}

///|
pub fn[S] LibraryAsyncLogger::new(
  sink : S,
  config? : AsyncLoggerConfig = AsyncLoggerConfig::new(),
  min_level? : @bitlogger.Level = @bitlogger.Level::Info,
  target? : String = "",
  flush? : (S) -> Int raise = fn(_) { 0 },
) -> LibraryAsyncLogger[S] {
  library_async_logger(async_logger(sink, config~, min_level~, target~, flush~))
}

///|
pub fn[S] LibraryAsyncLogger::to_async_logger(
  self : LibraryAsyncLogger[S],
) -> AsyncLogger[S] {
  self.inner
}

///|
fn[S] configured_library_async_logger(
  logger : AsyncLogger[S],
) -> LibraryAsyncLogger[S] {
  library_async_logger(logger)
}

///|
pub fn build_library_async_logger(
  config : AsyncLoggerBuildConfig,
) -> LibraryAsyncLogger[@bitlogger.RuntimeSink] {
  configured_library_async_logger(build_async_logger(config))
}

///|
pub fn build_library_async_text_logger(
  config : AsyncLoggerBuildConfig,
) -> LibraryAsyncLogger[@bitlogger.FormattedConsoleSink] {
  configured_library_async_logger(build_async_text_logger(config))
}

///|
pub fn parse_and_build_library_async_logger(
  input : String,
) -> LibraryAsyncLogger[@bitlogger.RuntimeSink] raise {
  build_library_async_logger(parse_async_logger_build_config_text(input))
}

///|
pub fn[S] LibraryAsyncLogger::with_target(
  self : LibraryAsyncLogger[S],
  target : String,
) -> LibraryAsyncLogger[S] {
  library_async_logger(self.inner.with_target(target))
}

///|
pub fn[S] LibraryAsyncLogger::child(
  self : LibraryAsyncLogger[S],
  target : String,
) -> LibraryAsyncLogger[S] {
  library_async_logger(self.inner.child(target))
}

///|
pub fn[S] LibraryAsyncLogger::with_context_fields(
  self : LibraryAsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> LibraryAsyncLogger[S] {
  library_async_logger(self.inner.with_context_fields(fields))
}

///|
pub fn[S] LibraryAsyncLogger::bind(
  self : LibraryAsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> LibraryAsyncLogger[S] {
  self.with_context_fields(fields)
}

///|
pub fn[S] LibraryAsyncLogger::is_enabled(
  self : LibraryAsyncLogger[S],
  level : @bitlogger.Level,
) -> Bool {
  self.inner.is_enabled(level)
}

///|
pub async fn[S] LibraryAsyncLogger::log(
  self : LibraryAsyncLogger[S],
  level : @bitlogger.Level,
  message : String,
  fields? : Array[@bitlogger.Field] = [],
  target? : String = "",
) -> Unit {
  self.inner.log(level, message, fields~, target~)
}

///|
pub async fn[S] LibraryAsyncLogger::info(
  self : LibraryAsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.inner.info(message, fields~)
}

///|
pub async fn[S] LibraryAsyncLogger::warn(
  self : LibraryAsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.inner.warn(message, fields~)
}

///|
pub async fn[S] LibraryAsyncLogger::error(
  self : LibraryAsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.inner.error(message, fields~)
}

///|
pub async fn[S : @bitlogger.Sink] LibraryAsyncLogger::run(
  self : LibraryAsyncLogger[S],
) -> Unit {
  self.inner.run()
}

///|
pub async fn[S] LibraryAsyncLogger::shutdown(
  self : LibraryAsyncLogger[S],
  clear? : Bool = false,
) -> Unit {
  self.inner.shutdown(clear~)
}
