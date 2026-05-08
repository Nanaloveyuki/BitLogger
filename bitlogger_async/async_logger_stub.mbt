pub(all) suberror AsyncLoggerClosed {
  AsyncLoggerClosed
}

pub(all) enum AsyncOverflowPolicy {
  Blocking
  DropOldest
  DropNewest
}

pub struct AsyncLoggerConfig {
  max_pending : Int
  overflow : AsyncOverflowPolicy
}

pub fn AsyncLoggerConfig::new(
  max_pending~ : Int = 0,
  overflow~ : AsyncOverflowPolicy = AsyncOverflowPolicy::Blocking,
) -> AsyncLoggerConfig {
  { max_pending, overflow }
}

pub struct AsyncLogger[S] {}

pub struct AsyncLoggerBuildConfig {
  logger : @bitlogger.LoggerConfig
  async_config : AsyncLoggerConfig
}

pub fn AsyncLoggerBuildConfig::new(
  logger~ : @bitlogger.LoggerConfig = @bitlogger.default_logger_config(),
  async_config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
) -> AsyncLoggerBuildConfig {
  { logger, async_config }
}

pub fn parse_async_logger_build_config_text(input : String) -> AsyncLoggerBuildConfig raise {
  ignore(input)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn async_logger[S : @bitlogger.Sink](
  sink : S,
  config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
  min_level~ : @bitlogger.Level = @bitlogger.Level::Info,
  target~ : String = "",
) -> AsyncLogger[S] {
  ignore(sink)
  ignore(config)
  ignore(min_level)
  ignore(target)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::with_timestamp(self : AsyncLogger[S], enabled~ : Bool = true) -> AsyncLogger[S] {
  ignore(self)
  ignore(enabled)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::with_target(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {
  ignore(self)
  ignore(target)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::with_context_fields(
  self : AsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> AsyncLogger[S] {
  ignore(self)
  ignore(fields)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::with_filter(
  self : AsyncLogger[S],
  predicate : (@bitlogger.Record) -> Bool,
) -> AsyncLogger[S] {
  ignore(self)
  ignore(predicate)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::with_patch(
  self : AsyncLogger[S],
  patch : @bitlogger.RecordPatch,
) -> AsyncLogger[S] {
  ignore(self)
  ignore(patch)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::with_min_level(
  self : AsyncLogger[S],
  min_level : @bitlogger.Level,
) -> AsyncLogger[S] {
  ignore(self)
  ignore(min_level)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::child(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {
  ignore(self)
  ignore(target)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::is_enabled(self : AsyncLogger[S], level : @bitlogger.Level) -> Bool {
  ignore(self)
  ignore(level)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::pending_count(self : AsyncLogger[S]) -> Int {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::dropped_count(self : AsyncLogger[S]) -> Int {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::is_closed(self : AsyncLogger[S]) -> Bool {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::is_running(self : AsyncLogger[S]) -> Bool {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::has_failed(self : AsyncLogger[S]) -> Bool {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::last_error(self : AsyncLogger[S]) -> String {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn[S] AsyncLogger::close(self : AsyncLogger[S], clear? : Bool = false) -> Unit {
  ignore(self)
  ignore(clear)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub async fn[S] AsyncLogger::wait_idle(self : AsyncLogger[S]) -> Unit {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub async fn[S] AsyncLogger::shutdown(self : AsyncLogger[S], clear? : Bool = false) -> Unit {
  ignore(self)
  ignore(clear)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub async fn[S : @bitlogger.Sink] AsyncLogger::run(self : AsyncLogger[S]) -> Unit {
  ignore(self)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn build_async_logger(
  config : AsyncLoggerBuildConfig,
) -> AsyncLogger[@bitlogger.RuntimeSink] {
  ignore(config)
  abort("bitlogger_async currently only supports native/llvm backends")
}

pub fn build_async_text_logger(config : AsyncLoggerBuildConfig) -> AsyncLogger[@bitlogger.FormattedConsoleSink] {
  ignore(config)
  abort("bitlogger_async currently only supports native/llvm backends")
}
