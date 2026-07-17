///|
pub(all) suberror AsyncLoggerClosed {
  AsyncLoggerClosed
}

///|
pub(all) suberror AsyncLoggerAlreadyRunning {
  AsyncLoggerAlreadyRunning
}

///|
pub type AsyncOverflowPolicy = @utils.AsyncOverflowPolicy

///|
pub type AsyncFlushPolicy = @utils.AsyncFlushPolicy

///|
pub type AsyncRuntimeMode = @utils.AsyncRuntimeMode

///|
fn all_async_runtime_modes() -> Array[AsyncRuntimeMode] {
  [
    @utils.native_worker_async_runtime_mode(),
    @utils.compatibility_async_runtime_mode(),
  ]
}

///|
pub type AsyncRuntimeState = @utils.AsyncRuntimeState

///|
pub type AsyncLifecyclePhase = @utils.AsyncLifecyclePhase

///|
pub type AsyncLoggerState = @utils.AsyncLoggerState

///|
pub fn async_runtime_mode_label(mode : AsyncRuntimeMode) -> String {
  @utils.async_runtime_mode_label(mode)
}

///|
pub fn async_runtime_state() -> AsyncRuntimeState {
  AsyncRuntimeState::new(
    async_runtime_mode(),
    async_runtime_supports_background_worker(),
  )
}

///|
pub fn async_runtime_state_to_json(state : AsyncRuntimeState) -> Json {
  @utils.async_runtime_state_to_json(state)
}

///|
pub fn stringify_async_runtime_state(
  state : AsyncRuntimeState,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_async_runtime_state(state, pretty~)
}

///|
pub fn async_logger_state_to_json(state : AsyncLoggerState) -> Json {
  @utils.async_logger_state_to_json(state)
}

///|
pub fn stringify_async_logger_state(
  state : AsyncLoggerState,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_async_logger_state(state, pretty~)
}

///|
pub type AsyncLoggerConfig = @utils.AsyncLoggerConfig

///|
pub fn parse_async_logger_config_text(
  input : String,
) -> AsyncLoggerConfig raise {
  @utils.parse_async_logger_config_text(input)
}

///|
pub fn async_logger_config_to_json(config : AsyncLoggerConfig) -> Json {
  @utils.async_logger_config_to_json(config)
}

///|
pub fn stringify_async_logger_config(
  config : AsyncLoggerConfig,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_async_logger_config(config, pretty~)
}

///|
pub type AsyncLoggerBuildConfig = @utils.AsyncLoggerBuildConfig

///|
pub fn parse_async_logger_build_config_text(
  input : String,
) -> AsyncLoggerBuildConfig raise {
  @utils.parse_async_logger_build_config_text(input)
}

///|
pub fn async_logger_build_config_to_json(
  config : AsyncLoggerBuildConfig,
) -> Json {
  @utils.async_logger_build_config_to_json(config)
}

///|
pub fn stringify_async_logger_build_config(
  config : AsyncLoggerBuildConfig,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_async_logger_build_config(config, pretty~)
}

///|
pub struct AsyncLogger[S] {
  min_level : @bitlogger.Level
  target : String
  timestamp : Bool
  overflow : AsyncOverflowPolicy
  max_batch : Int
  linger_ms : Int
  flush_policy : AsyncFlushPolicy
  sink : S
  flush_callback : (S) -> Unit raise
  context_fields : Array[@bitlogger.Field]
  filter : (@bitlogger.Record) -> Bool
  patch : @bitlogger.RecordPatch
  queue : @async.Queue[@bitlogger.Record]
  pending_count : Ref[Int]
  dropped_count : Ref[Int]
  phase : Ref[AsyncLifecyclePhase]
  last_error : Ref[String]
}

///|
pub fn[S] async_logger(
  sink : S,
  config? : AsyncLoggerConfig = AsyncLoggerConfig::new(),
  min_level? : @bitlogger.Level = @bitlogger.Level::Info,
  target? : String = "",
  flush? : (S) -> Unit raise = fn(_) { () },
) -> AsyncLogger[S] {
  {
    min_level,
    target,
    timestamp: false,
    overflow: config.overflow,
    max_batch: config.max_batch,
    linger_ms: config.linger_ms,
    flush_policy: config.flush,
    sink,
    flush_callback: flush,
    context_fields: [],
    filter: fn(_) { true },
    patch: @bitlogger.identity_patch(),
    queue: @async.Queue(kind=queue_kind_of(config)),
    pending_count: Ref(0),
    dropped_count: Ref(0),
    phase: Ref(AsyncLifecyclePhase::Ready),
    last_error: Ref(""),
  }
}

///|
fn async_logger_phase_is_closed(phase : AsyncLifecyclePhase) -> Bool {
  match phase {
    AsyncLifecyclePhase::Closing
    | AsyncLifecyclePhase::Closed
    | AsyncLifecyclePhase::ClosedFailed => true
    _ => false
  }
}

///|
fn async_logger_phase_is_running(phase : AsyncLifecyclePhase) -> Bool {
  match phase {
    AsyncLifecyclePhase::Running | AsyncLifecyclePhase::Closing => true
    _ => false
  }
}

///|
fn async_logger_phase_has_failed(phase : AsyncLifecyclePhase) -> Bool {
  match phase {
    AsyncLifecyclePhase::Failed | AsyncLifecyclePhase::ClosedFailed => true
    _ => false
  }
}

///|
fn async_logger_phase_after_close(
  phase : AsyncLifecyclePhase,
) -> AsyncLifecyclePhase {
  match phase {
    AsyncLifecyclePhase::Running | AsyncLifecyclePhase::Closing =>
      AsyncLifecyclePhase::Closing
    AsyncLifecyclePhase::Failed | AsyncLifecyclePhase::ClosedFailed =>
      AsyncLifecyclePhase::ClosedFailed
    AsyncLifecyclePhase::Closed => AsyncLifecyclePhase::Closed
    AsyncLifecyclePhase::Ready => AsyncLifecyclePhase::Closed
  }
}

///|
fn async_logger_phase_after_run_exit(
  phase : AsyncLifecyclePhase,
) -> AsyncLifecyclePhase {
  match phase {
    AsyncLifecyclePhase::Closing => AsyncLifecyclePhase::Closed
    AsyncLifecyclePhase::Running => AsyncLifecyclePhase::Ready
    AsyncLifecyclePhase::Closed | AsyncLifecyclePhase::ClosedFailed => phase
    _ => phase
  }
}

///|
fn async_logger_phase_after_run_failure(
  phase : AsyncLifecyclePhase,
) -> AsyncLifecyclePhase {
  match phase {
    AsyncLifecyclePhase::Closing => AsyncLifecyclePhase::ClosedFailed
    AsyncLifecyclePhase::Closed | AsyncLifecyclePhase::ClosedFailed =>
      AsyncLifecyclePhase::ClosedFailed
    _ => AsyncLifecyclePhase::Failed
  }
}

///|
pub fn[S] AsyncLogger::phase(self : AsyncLogger[S]) -> AsyncLifecyclePhase {
  self.phase.val
}

///|
fn queue_kind_of(config : AsyncLoggerConfig) -> @aqueue.Kind {
  let limit = if config.max_pending < 0 { 0 } else { config.max_pending }
  match config.overflow {
    AsyncOverflowPolicy::Blocking => @aqueue.Kind::Blocking(limit)
    AsyncOverflowPolicy::DropOldest => @aqueue.Kind::DiscardOldest(limit)
    AsyncOverflowPolicy::DropNewest => @aqueue.Kind::DiscardLatest(limit)
  }
}

///|
pub fn[S] AsyncLogger::with_timestamp(
  self : AsyncLogger[S],
  enabled? : Bool = true,
) -> AsyncLogger[S] {
  { ..self, timestamp: enabled }
}

///|
pub fn[S] AsyncLogger::with_target(
  self : AsyncLogger[S],
  target : String,
) -> AsyncLogger[S] {
  { ..self, target, }
}

///|
pub fn[S] AsyncLogger::with_context_fields(
  self : AsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> AsyncLogger[S] {
  { ..self, context_fields: fields }
}

///|
pub fn[S] AsyncLogger::with_filter(
  self : AsyncLogger[S],
  predicate : (@bitlogger.Record) -> Bool,
) -> AsyncLogger[S] {
  let current = self.filter
  { ..self, filter: fn(rec) { current(rec) && predicate(rec) } }
}

///|
pub fn[S] AsyncLogger::with_patch(
  self : AsyncLogger[S],
  patch : @bitlogger.RecordPatch,
) -> AsyncLogger[S] {
  let current = self.patch
  { ..self, patch: fn(rec) { patch(current(rec)) } }
}

///|
pub fn[S] AsyncLogger::with_min_level(
  self : AsyncLogger[S],
  min_level : @bitlogger.Level,
) -> AsyncLogger[S] {
  { ..self, min_level, }
}

///|
fn combine_targets(parent : String, child : String) -> String {
  if parent == "" {
    child
  } else if child == "" {
    parent
  } else {
    "\{parent}.\{child}"
  }
}

///|
pub fn[S] AsyncLogger::child(
  self : AsyncLogger[S],
  target : String,
) -> AsyncLogger[S] {
  { ..self, target: combine_targets(self.target, target) }
}

///|
pub fn[S] AsyncLogger::is_enabled(
  self : AsyncLogger[S],
  level : @bitlogger.Level,
) -> Bool {
  level.enabled(self.min_level)
}

///|
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

///|
pub async fn[S] AsyncLogger::log(
  self : AsyncLogger[S],
  level : @bitlogger.Level,
  message : String,
  fields? : Array[@bitlogger.Field] = [],
  target? : String = "",
) -> Unit {
  guard !self.is_closed() else { () }
  guard self.is_enabled(level) else { () }
  let actual_target = if target == "" { self.target } else { target }
  let timestamp_ms = if self.timestamp { @env.now() } else { 0UL }
  let rec = @bitlogger.Record::new(
    level,
    message,
    timestamp_ms~,
    target=actual_target,
    fields=merge_fields(self.context_fields, fields),
  )
  let rec = (self.patch)(rec)
  guard (self.filter)(rec) else { () }
  let accepted = self.queue.try_put(rec) catch {
    err if err is AsyncLoggerClosed => false
    err => raise err
  }
  if accepted {
    self.pending_count.val += 1
  } else {
    match self.overflow {
      AsyncOverflowPolicy::Blocking => {
        let accepted = (async fn() -> Bool {
          self.queue.put(rec)
          true
        })() catch {
          err if err is AsyncLoggerClosed => false
          err => raise err
        }
        if accepted {
          self.pending_count.val += 1
        }
      }
      AsyncOverflowPolicy::DropOldest | AsyncOverflowPolicy::DropNewest =>
        self.dropped_count.val += 1
    }
  }
}

///|
pub async fn[S] AsyncLogger::trace(
  self : AsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Trace, message, fields~)
}

///|
pub async fn[S] AsyncLogger::debug(
  self : AsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Debug, message, fields~)
}

///|
pub async fn[S] AsyncLogger::info(
  self : AsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Info, message, fields~)
}

///|
pub async fn[S] AsyncLogger::warn(
  self : AsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Warn, message, fields~)
}

///|
pub async fn[S] AsyncLogger::error(
  self : AsyncLogger[S],
  message : String,
  fields? : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Error, message, fields~)
}

///|
pub fn[S] AsyncLogger::pending_count(self : AsyncLogger[S]) -> Int {
  self.pending_count.val
}

///|
pub fn[S] AsyncLogger::dropped_count(self : AsyncLogger[S]) -> Int {
  self.dropped_count.val
}

///|
pub fn[S] AsyncLogger::is_closed(self : AsyncLogger[S]) -> Bool {
  async_logger_phase_is_closed(self.phase())
}

///|
pub fn[S] AsyncLogger::is_running(self : AsyncLogger[S]) -> Bool {
  async_logger_phase_is_running(self.phase())
}

///|
pub fn[S] AsyncLogger::has_failed(self : AsyncLogger[S]) -> Bool {
  async_logger_phase_has_failed(self.phase())
}

///|
pub fn[S] AsyncLogger::last_error(self : AsyncLogger[S]) -> String {
  self.last_error.val
}

///|
pub fn[S] AsyncLogger::flush_policy(self : AsyncLogger[S]) -> AsyncFlushPolicy {
  self.flush_policy
}

///|
pub fn[S] AsyncLogger::state(self : AsyncLogger[S]) -> AsyncLoggerState {
  AsyncLoggerState::new(
    async_runtime_state(),
    self.phase(),
    self.pending_count(),
    self.dropped_count(),
    self.last_error(),
    self.flush_policy(),
  )
}

///|
pub fn[S] AsyncLogger::close(
  self : AsyncLogger[S],
  clear? : Bool = false,
) -> Unit {
  self.phase.val = async_logger_phase_after_close(self.phase())
  if clear {
    let abandoned = self.pending_count()
    if abandoned > 0 {
      self.dropped_count.val += abandoned
      self.pending_count.val = 0
    }
  }
  self.queue.close(error=AsyncLoggerClosed, clear~)
}

///|
pub async fn[S] AsyncLogger::wait_idle(self : AsyncLogger[S]) -> Unit {
  while self.pending_count() > 0 {
    if self.has_failed() {
      break
    }
    @async.pause()
  }
}

///|
pub async fn[S] AsyncLogger::shutdown(
  self : AsyncLogger[S],
  clear? : Bool = false,
) -> Unit {
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

///|
fn[S] run_flush_callback(logger : AsyncLogger[S]) -> Unit raise {
  (logger.flush_callback)(logger.sink)
}

///|
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
    for drained = 1; drained < logger.max_batch; {
      let next = logger.queue.try_get() catch {
        err if err is AsyncLoggerClosed => None
        err => raise err
      }
      match next {
        Some(next) => {
          logger.sink.write(next)
          if logger.pending_count.val > 0 {
            logger.pending_count.val -= 1
          }
          continue drained + 1
        }
        None => {
          if logger.linger_ms <= 0 {
            break
          }
          let waited = @async.with_timeout_opt(logger.linger_ms, () => {
            logger.queue.get()
          }) catch {
            err if err is AsyncLoggerClosed => None
            err => raise err
          }
          match waited {
            Some(next) => {
              logger.sink.write(next)
              if logger.pending_count.val > 0 {
                logger.pending_count.val -= 1
              }
              continue drained + 1
            }
            None => break
          }
        }
      }
    }
    match logger.flush_policy {
      AsyncFlushPolicy::Batch => run_flush_callback(logger)
      _ => ()
    }
  }
  match logger.flush_policy {
    AsyncFlushPolicy::Shutdown => run_flush_callback(logger)
    _ => ()
  }
}

///|
pub async fn[S : @bitlogger.Sink] AsyncLogger::run(
  self : AsyncLogger[S],
) -> Unit {
  guard !self.is_closed() else { raise AsyncLoggerClosed }
  guard !self.is_running() else { raise AsyncLoggerAlreadyRunning }
  self.phase.val = AsyncLifecyclePhase::Running
  self.last_error.val = ""
  run_worker(self) catch {
    err => {
      self.phase.val = async_logger_phase_after_run_failure(self.phase())
      self.last_error.val = err.to_string()
      raise err
    }
  }
  self.phase.val = async_logger_phase_after_run_exit(self.phase())
}

///|
pub fn build_async_logger(
  config : AsyncLoggerBuildConfig,
) -> AsyncLogger[@bitlogger.RuntimeSink] {
  let logger = @bitlogger.build_logger(config.logger)
  async_logger(
    logger.sink,
    config=config.async_config,
    min_level=logger.min_level,
    target=logger.target,
    flush=fn(sink) { ignore(sink.flush_progress()) },
  ).with_timestamp(enabled=logger.timestamp)
}

///|
pub fn build_async_text_logger(
  config : AsyncLoggerBuildConfig,
) -> AsyncLogger[@bitlogger.FormattedConsoleSink] {
  async_logger(
    @bitlogger.text_console_sink(
      config.logger.sink.text_formatter.to_formatter(),
    ),
    config=config.async_config,
    min_level=config.logger.min_level,
    target=config.logger.target,
  ).with_timestamp(enabled=config.logger.timestamp)
}
