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
