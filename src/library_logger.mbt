///|
pub struct LibraryLogger[S] {
  inner : Logger[S]
}

///|
fn[S] library_logger(logger : Logger[S]) -> LibraryLogger[S] {
  { inner: logger }
}

///|
pub fn[S] Logger::to_library_logger(self : Logger[S]) -> LibraryLogger[S] {
  library_logger(self)
}

///|
pub fn[S] LibraryLogger::new(
  sink : S,
  min_level? : Level = Level::Info,
  target? : String = "",
) -> LibraryLogger[S] {
  library_logger(Logger::new(sink, min_level~, target~))
}

///|
pub fn[S] LibraryLogger::to_logger(self : LibraryLogger[S]) -> Logger[S] {
  self.inner
}

///|
fn configured_library_logger(
  logger : ConfiguredLogger,
) -> LibraryLogger[RuntimeSink] {
  library_logger(logger)
}

///|
pub fn build_library_logger(
  config : LoggerConfig,
) -> LibraryLogger[RuntimeSink] {
  configured_library_logger(build_logger(config))
}

///|
pub fn parse_and_build_library_logger(
  input : String,
) -> LibraryLogger[RuntimeSink] raise ConfigError {
  configured_library_logger(parse_and_build_logger(input))
}

///|
pub fn[S] LibraryLogger::with_target(
  self : LibraryLogger[S],
  target : String,
) -> LibraryLogger[S] {
  library_logger(self.inner.with_target(target))
}

///|
pub fn[S] LibraryLogger::child(
  self : LibraryLogger[S],
  target : String,
) -> LibraryLogger[S] {
  library_logger(self.inner.child(target))
}

///|
pub fn[S] LibraryLogger::with_context_fields(
  self : LibraryLogger[S],
  fields : Array[Field],
) -> LibraryLogger[ContextSink[S]] {
  library_logger(self.inner.with_context_fields(fields))
}

///|
pub fn[S] LibraryLogger::bind(
  self : LibraryLogger[S],
  fields : Array[Field],
) -> LibraryLogger[ContextSink[S]] {
  self.with_context_fields(fields)
}

///|
pub fn[S] LibraryLogger::is_enabled(
  self : LibraryLogger[S],
  level : Level,
) -> Bool {
  self.inner.is_enabled(level)
}

///|
pub fn[S : Sink] LibraryLogger::log(
  self : LibraryLogger[S],
  level : Level,
  message : String,
  fields? : Array[Field] = [],
  target? : String = "",
) -> Unit {
  self.inner.log(level, message, fields~, target~)
}

///|
pub fn[S : Sink] LibraryLogger::info(
  self : LibraryLogger[S],
  message : String,
  fields? : Array[Field] = [],
) -> Unit {
  self.inner.info(message, fields~)
}

///|
pub fn[S : Sink] LibraryLogger::warn(
  self : LibraryLogger[S],
  message : String,
  fields? : Array[Field] = [],
) -> Unit {
  self.inner.warn(message, fields~)
}

///|
pub fn[S : Sink] LibraryLogger::error(
  self : LibraryLogger[S],
  message : String,
  fields? : Array[Field] = [],
) -> Unit {
  self.inner.error(message, fields~)
}

///|
pub fn default_library_logger() -> LibraryLogger[ConsoleSink] {
  library_logger(default_logger())
}
