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

fn parse_async_overflow(name : String) -> AsyncOverflowPolicy raise {
  match name.to_upper() {
    "BLOCKING" => AsyncOverflowPolicy::Blocking
    "DROPOLDEST" => AsyncOverflowPolicy::DropOldest
    "DROPLATEST" => AsyncOverflowPolicy::DropNewest
    "DROPNEWEST" => AsyncOverflowPolicy::DropNewest
    _ => raise Failure::Failure("Unsupported async overflow policy: " + name)
  }
}

pub fn parse_async_logger_config_text(input : String) -> AsyncLoggerConfig raise {
  let root = @json_parser.parse(input)
  let obj = match root.as_object() {
    Some(obj) => obj
    None => raise Failure::Failure("Expected object for async logger config")
  }
  let max_pending = match obj.get("max_pending") {
    Some(value) => match value.as_number() {
      Some(number) => number.to_int()
      None => raise Failure::Failure("Expected number at async_config.max_pending")
    }
    None => 0
  }
  let overflow = match obj.get("overflow") {
    Some(value) => match value.as_string() {
      Some(text) => parse_async_overflow(text)
      None => raise Failure::Failure("Expected string at async_config.overflow")
    }
    None => AsyncOverflowPolicy::Blocking
  }
  AsyncLoggerConfig::new(max_pending=max_pending, overflow=overflow)
}

pub fn async_logger_config_to_json(config : AsyncLoggerConfig) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "max_pending": @json_parser.JsonValue::Number(config.max_pending.to_double()),
    "overflow": @json_parser.JsonValue::String(match config.overflow {
      AsyncOverflowPolicy::Blocking => "Blocking"
      AsyncOverflowPolicy::DropOldest => "DropOldest"
      AsyncOverflowPolicy::DropNewest => "DropNewest"
    }),
  })
}

pub fn stringify_async_logger_config(config : AsyncLoggerConfig, pretty~ : Bool = false) -> String {
  let value = async_logger_config_to_json(config)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

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
  let root = @json_parser.parse(input)
  let obj = match root.as_object() {
    Some(obj) => obj
    None => raise Failure::Failure("Expected object at async logger build config root")
  }
  let logger = match obj.get("logger") {
    Some(value) => @bitlogger.parse_logger_config_text(@json_parser.stringify(value))
    None => @bitlogger.default_logger_config()
  }
  let async_config = match obj.get("async_config") {
    Some(value) => parse_async_logger_config_text(@json_parser.stringify(value))
    None => AsyncLoggerConfig::new()
  }
  AsyncLoggerBuildConfig::new(logger=logger, async_config=async_config)
}

pub fn async_logger_build_config_to_json(
  config : AsyncLoggerBuildConfig,
) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "logger": @bitlogger.logger_config_to_json(config.logger),
    "async_config": async_logger_config_to_json(config.async_config),
  })
}

pub fn stringify_async_logger_build_config(
  config : AsyncLoggerBuildConfig,
  pretty~ : Bool = false,
) -> String {
  let value = async_logger_build_config_to_json(config)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

pub struct AsyncLogger[S] {
  min_level : @bitlogger.Level
  target : String
  timestamp : Bool
  overflow : AsyncOverflowPolicy
  sink : S
  context_fields : Array[@bitlogger.Field]
  filter : (@bitlogger.Record) -> Bool
  patch : @bitlogger.RecordPatch
  queue : @async.Queue[@bitlogger.Record]
  pending_count : Ref[Int]
  dropped_count : Ref[Int]
  is_closed : Ref[Bool]
  is_running : Ref[Bool]
  has_failed : Ref[Bool]
  last_error : Ref[String]
}

pub fn[S] async_logger(
  sink : S,
  config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
  min_level~ : @bitlogger.Level = @bitlogger.Level::Info,
  target~ : String = "",
) -> AsyncLogger[S] {
  {
    min_level,
    target,
    timestamp: false,
    overflow: config.overflow,
    sink,
    context_fields: [],
    filter: fn(_) { true },
    patch: @bitlogger.identity_patch(),
    queue: @async.Queue::new(kind=queue_kind_of(config)),
    pending_count: Ref::new(0),
    dropped_count: Ref::new(0),
    is_closed: Ref::new(false),
    is_running: Ref::new(false),
    has_failed: Ref::new(false),
    last_error: Ref::new(""),
  }
}

fn queue_kind_of(config : AsyncLoggerConfig) -> @aqueue.Kind {
  let limit = if config.max_pending < 0 { 0 } else { config.max_pending }
  match config.overflow {
    AsyncOverflowPolicy::Blocking => @aqueue.Kind::Blocking(limit)
    AsyncOverflowPolicy::DropOldest => @aqueue.Kind::DiscardOldest(limit)
    AsyncOverflowPolicy::DropNewest => @aqueue.Kind::DiscardLatest(limit)
  }
}

pub fn[S] AsyncLogger::with_timestamp(self : AsyncLogger[S], enabled~ : Bool = true) -> AsyncLogger[S] {
  { ..self, timestamp: enabled }
}

pub fn[S] AsyncLogger::with_target(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {
  { ..self, target }
}

pub fn[S] AsyncLogger::with_context_fields(
  self : AsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> AsyncLogger[S] {
  { ..self, context_fields: fields }
}

pub fn[S] AsyncLogger::with_filter(
  self : AsyncLogger[S],
  predicate : (@bitlogger.Record) -> Bool,
) -> AsyncLogger[S] {
  let current = self.filter
  {
    ..self,
    filter: fn(rec) {
      current(rec) && predicate(rec)
    },
  }
}

pub fn[S] AsyncLogger::with_patch(
  self : AsyncLogger[S],
  patch : @bitlogger.RecordPatch,
) -> AsyncLogger[S] {
  let current = self.patch
  {
    ..self,
    patch: fn(rec) {
      patch(current(rec))
    },
  }
}

pub fn[S] AsyncLogger::with_min_level(
  self : AsyncLogger[S],
  min_level : @bitlogger.Level,
) -> AsyncLogger[S] {
  { ..self, min_level }
}

fn combine_targets(parent : String, child : String) -> String {
  if parent == "" {
    child
  } else if child == "" {
    parent
  } else {
    "\{parent}.\{child}"
  }
}

pub fn[S] AsyncLogger::child(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {
  { ..self, target: combine_targets(self.target, target) }
}

pub fn[S] AsyncLogger::is_enabled(self : AsyncLogger[S], level : @bitlogger.Level) -> Bool {
  level.enabled(self.min_level)
}

pub async fn[S] AsyncLogger::log(
  self : AsyncLogger[S],
  level : @bitlogger.Level,
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
  target? : String = "",
) -> Unit {
  guard self.is_enabled(level) else {
    ()
  }
  let actual_target = if target == "" { self.target } else { target }
  let timestamp_ms = if self.timestamp { @env.now() } else { 0UL }
  let rec = @bitlogger.Record::new(
    level,
    message,
    timestamp_ms=timestamp_ms,
    target=actual_target,
    fields=merge_fields(self.context_fields, fields),
  )
  let rec = (self.patch)(rec)
  guard (self.filter)(rec) else {
    ()
  }
  let accepted = self.queue.try_put(rec) catch {
    err if err is AsyncLoggerClosed => false
    err => raise err
  }
  if accepted {
    self.pending_count.val += 1
  } else {
    match self.overflow {
      AsyncOverflowPolicy::Blocking => {
        self.queue.put(rec) catch {
          err if err is AsyncLoggerClosed => ()
          err => raise err
        }
        self.pending_count.val += 1
      }
      AsyncOverflowPolicy::DropOldest | AsyncOverflowPolicy::DropNewest => {
        self.dropped_count.val += 1
      }
    }
  }
}

fn merge_fields(
  left : Array[@bitlogger.Field],
  right : Array[@bitlogger.Field],
) -> Array[@bitlogger.Field] {
  if left.length() == 0 {
    right
  } else if right.length() == 0 {
    left
  } else {
    left + right
  }
}

pub async fn[S] AsyncLogger::trace(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Trace, message, fields=fields)
}

pub async fn[S] AsyncLogger::debug(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Debug, message, fields=fields)
}

pub async fn[S] AsyncLogger::info(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Info, message, fields=fields)
}

pub async fn[S] AsyncLogger::warn(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Warn, message, fields=fields)
}

pub async fn[S] AsyncLogger::error(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Error, message, fields=fields)
}

pub fn[S] AsyncLogger::pending_count(self : AsyncLogger[S]) -> Int {
  self.pending_count.val
}

pub fn[S] AsyncLogger::dropped_count(self : AsyncLogger[S]) -> Int {
  self.dropped_count.val
}

pub fn[S] AsyncLogger::is_closed(self : AsyncLogger[S]) -> Bool {
  self.is_closed.val
}

pub fn[S] AsyncLogger::is_running(self : AsyncLogger[S]) -> Bool {
  self.is_running.val
}

pub fn[S] AsyncLogger::has_failed(self : AsyncLogger[S]) -> Bool {
  self.has_failed.val
}

pub fn[S] AsyncLogger::last_error(self : AsyncLogger[S]) -> String {
  self.last_error.val
}

pub fn[S] AsyncLogger::close(self : AsyncLogger[S], clear? : Bool = false) -> Unit {
  self.is_closed.val = true
  if clear {
    let abandoned = self.pending_count.val
    if abandoned > 0 {
      self.dropped_count.val += abandoned
      self.pending_count.val = 0
    }
  }
  self.queue.close(error=AsyncLoggerClosed, clear=clear)
}

pub async fn[S] AsyncLogger::shutdown(self : AsyncLogger[S], clear? : Bool = false) -> Unit {
  if clear {
    self.close(clear=true)
  } else {
    self.wait_idle()
    if self.pending_count() > 0 {
      self.close(clear=true)
    } else {
      self.close()
    }
  }
  while self.is_running() {
    @async.pause()
  }
}

pub async fn[S] AsyncLogger::wait_idle(self : AsyncLogger[S]) -> Unit {
  while self.pending_count() > 0 {
    if self.has_failed() {
      break
    }
    @async.pause()
  }
}

async fn[S : @bitlogger.Sink] run_worker(logger : AsyncLogger[S]) -> Unit {
  while true {
    let rec = logger.queue.get() catch {
      err if err is AsyncLoggerClosed => break
      err => raise err
    }
    logger.sink.write(rec)
    if logger.pending_count.val > 0 {
      logger.pending_count.val -= 1
    }
  }
}

pub async fn[S : @bitlogger.Sink] AsyncLogger::run(self : AsyncLogger[S]) -> Unit {
  self.is_running.val = true
  self.has_failed.val = false
  self.last_error.val = ""
  run_worker(self) catch {
    err => {
      self.has_failed.val = true
      self.last_error.val = err.to_string()
      self.is_running.val = false
      raise err
    }
  }
  self.is_running.val = false
}

pub fn build_async_logger(
  config : AsyncLoggerBuildConfig,
) -> AsyncLogger[@bitlogger.RuntimeSink] {
  let logger = @bitlogger.build_logger(config.logger)
  async_logger(
    logger.sink,
    config=config.async_config,
    min_level=logger.min_level,
    target=logger.target,
  ).with_timestamp(enabled=logger.timestamp)
}

pub fn build_async_text_logger(config : AsyncLoggerBuildConfig) -> AsyncLogger[@bitlogger.FormattedConsoleSink] {
  async_logger(
    @bitlogger.text_console_sink(config.logger.sink.text_formatter.to_formatter()),
    config=config.async_config,
    min_level=config.logger.min_level,
    target=config.logger.target,
  ).with_timestamp(enabled=config.logger.timestamp)
}
