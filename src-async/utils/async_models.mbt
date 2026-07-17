///|
pub(all) enum AsyncOverflowPolicy {
  Blocking
  DropOldest
  DropNewest
}

///|
pub(all) enum AsyncFlushPolicy {
  Never
  Batch
  Shutdown
}

///|
pub enum AsyncRuntimeMode {
  NativeWorker
  Compatibility
}

///|
pub fn async_runtime_mode_label(mode : AsyncRuntimeMode) -> String {
  match mode {
    AsyncRuntimeMode::NativeWorker => "native_worker"
    AsyncRuntimeMode::Compatibility => "compatibility"
  }
}

///|
pub fn native_worker_async_runtime_mode() -> AsyncRuntimeMode {
  AsyncRuntimeMode::NativeWorker
}

///|
pub fn compatibility_async_runtime_mode() -> AsyncRuntimeMode {
  AsyncRuntimeMode::Compatibility
}

///|
pub struct AsyncRuntimeState {
  mode : AsyncRuntimeMode
  background_worker : Bool
}

///|
pub fn AsyncRuntimeState::new(
  mode : AsyncRuntimeMode,
  background_worker : Bool,
) -> AsyncRuntimeState {
  { mode, background_worker }
}

///|
pub(all) enum AsyncLifecyclePhase {
  Ready
  Running
  Failed
  Closing
  Closed
  ClosedFailed
}

///|
fn async_lifecycle_phase_label(phase : AsyncLifecyclePhase) -> String {
  match phase {
    AsyncLifecyclePhase::Ready => "ready"
    AsyncLifecyclePhase::Running => "running"
    AsyncLifecyclePhase::Failed => "failed"
    AsyncLifecyclePhase::Closing => "closing"
    AsyncLifecyclePhase::Closed => "closed"
    AsyncLifecyclePhase::ClosedFailed => "closed_failed"
  }
}

///|
fn async_lifecycle_phase_is_closed(phase : AsyncLifecyclePhase) -> Bool {
  match phase {
    AsyncLifecyclePhase::Closing
    | AsyncLifecyclePhase::Closed
    | AsyncLifecyclePhase::ClosedFailed => true
    _ => false
  }
}

///|
fn async_lifecycle_phase_is_running(phase : AsyncLifecyclePhase) -> Bool {
  match phase {
    AsyncLifecyclePhase::Running | AsyncLifecyclePhase::Closing => true
    _ => false
  }
}

///|
fn async_lifecycle_phase_has_failed(phase : AsyncLifecyclePhase) -> Bool {
  match phase {
    AsyncLifecyclePhase::Failed | AsyncLifecyclePhase::ClosedFailed => true
    _ => false
  }
}

///|
fn async_lifecycle_phase_can_rerun(phase : AsyncLifecyclePhase) -> Bool {
  match phase {
    AsyncLifecyclePhase::Ready | AsyncLifecyclePhase::Failed => true
    _ => false
  }
}

///|
pub struct AsyncLoggerState {
  runtime : AsyncRuntimeState
  phase : AsyncLifecyclePhase
  pending_count : Int
  dropped_count : Int
  is_closed : Bool
  is_running : Bool
  has_failed : Bool
  backlog_retained : Bool
  can_rerun : Bool
  terminal : Bool
  last_error : String
  flush_policy : AsyncFlushPolicy
}

///|
pub fn AsyncLoggerState::new(
  runtime : AsyncRuntimeState,
  phase : AsyncLifecyclePhase,
  pending_count : Int,
  dropped_count : Int,
  last_error : String,
  flush_policy : AsyncFlushPolicy,
) -> AsyncLoggerState {
  let is_closed = async_lifecycle_phase_is_closed(phase)
  let is_running = async_lifecycle_phase_is_running(phase)
  let has_failed = async_lifecycle_phase_has_failed(phase)
  let backlog_retained = pending_count > 0 && !is_running
  let can_rerun = async_lifecycle_phase_can_rerun(phase)
  let terminal = is_closed && !is_running && pending_count == 0
  {
    runtime,
    phase,
    pending_count,
    dropped_count,
    is_closed,
    is_running,
    has_failed,
    backlog_retained,
    can_rerun,
    terminal,
    last_error,
    flush_policy,
  }
}

///|
pub fn async_runtime_state_to_json(state : AsyncRuntimeState) -> Json {
  Json::object({
    "mode": Json::string(async_runtime_mode_label(state.mode)),
    "background_worker": Json::boolean(state.background_worker),
  })
}

///|
pub fn stringify_async_runtime_state(
  state : AsyncRuntimeState,
  pretty? : Bool = false,
) -> String {
  let value = async_runtime_state_to_json(state)
  if pretty {
    value.stringify(indent=2)
  } else {
    value.stringify()
  }
}

///|
fn async_flush_policy_label(policy : AsyncFlushPolicy) -> String {
  match policy {
    AsyncFlushPolicy::Never => "Never"
    AsyncFlushPolicy::Batch => "Batch"
    AsyncFlushPolicy::Shutdown => "Shutdown"
  }
}

///|
fn async_logger_state_to_json_value(state : AsyncLoggerState) -> Json {
  Json::object({
    "runtime": async_runtime_state_to_json(state.runtime),
    "phase": Json::string(async_lifecycle_phase_label(state.phase)),
    "pending_count": Json::number(state.pending_count.to_double()),
    "dropped_count": Json::number(state.dropped_count.to_double()),
    "is_closed": Json::boolean(state.is_closed),
    "is_running": Json::boolean(state.is_running),
    "has_failed": Json::boolean(state.has_failed),
    "backlog_retained": Json::boolean(state.backlog_retained),
    "can_rerun": Json::boolean(state.can_rerun),
    "terminal": Json::boolean(state.terminal),
    "last_error": Json::string(state.last_error),
    "flush_policy": Json::string(async_flush_policy_label(state.flush_policy)),
  })
}

///|
pub fn async_logger_state_to_json(state : AsyncLoggerState) -> Json {
  async_logger_state_to_json_value(state)
}

///|
pub fn stringify_async_logger_state(
  state : AsyncLoggerState,
  pretty? : Bool = false,
) -> String {
  let value = async_logger_state_to_json_value(state)
  if pretty {
    value.stringify(indent=2)
  } else {
    value.stringify()
  }
}

///|
pub struct AsyncLoggerConfig {
  max_pending : Int
  overflow : AsyncOverflowPolicy
  max_batch : Int
  linger_ms : Int
  flush : AsyncFlushPolicy
}

///|
pub fn AsyncLoggerConfig::new(
  max_pending? : Int = 0,
  overflow? : AsyncOverflowPolicy = AsyncOverflowPolicy::Blocking,
  max_batch? : Int = 1,
  linger_ms? : Int = 0,
  flush? : AsyncFlushPolicy = AsyncFlushPolicy::Never,
) -> AsyncLoggerConfig {
  {
    max_pending,
    overflow,
    max_batch: if max_batch <= 1 {
      1
    } else {
      max_batch
    },
    linger_ms: if linger_ms < 0 {
      0
    } else {
      linger_ms
    },
    flush,
  }
}

///|
fn parse_async_overflow(name : String) -> AsyncOverflowPolicy raise {
  match name.to_upper() {
    "BLOCKING" => AsyncOverflowPolicy::Blocking
    "DROPOLDEST" => AsyncOverflowPolicy::DropOldest
    "DROPLATEST" => AsyncOverflowPolicy::DropNewest
    "DROPNEWEST" => AsyncOverflowPolicy::DropNewest
    _ => raise Failure::Failure("Unsupported async overflow policy: " + name)
  }
}

///|
fn parse_async_flush(name : String) -> AsyncFlushPolicy raise {
  match name.to_upper() {
    "NEVER" => AsyncFlushPolicy::Never
    "NONE" => AsyncFlushPolicy::Never
    "BATCH" => AsyncFlushPolicy::Batch
    "SHUTDOWN" => AsyncFlushPolicy::Shutdown
    _ => raise Failure::Failure("Unsupported async flush policy: " + name)
  }
}

///|
pub fn parse_async_logger_config_text(
  input : String,
) -> AsyncLoggerConfig raise {
  let root = @json.parse(input)
  let obj = match root {
    Json::Object(obj) => obj
    _ => raise Failure::Failure("Expected object for async logger config")
  }
  let max_pending = match obj.get("max_pending") {
    Some(Json::Number(number, ..)) => number.to_int()
    Some(_) =>
      raise Failure::Failure("Expected number at async_config.max_pending")
    None => 0
  }
  let overflow = match obj.get("overflow") {
    Some(Json::String(text)) => parse_async_overflow(text)
    Some(_) =>
      raise Failure::Failure("Expected string at async_config.overflow")
    None => AsyncOverflowPolicy::Blocking
  }
  let max_batch = match obj.get("max_batch") {
    Some(Json::Number(number, ..)) => number.to_int()
    Some(_) =>
      raise Failure::Failure("Expected number at async_config.max_batch")
    None => 1
  }
  let linger_ms = match obj.get("linger_ms") {
    Some(Json::Number(number, ..)) => number.to_int()
    Some(_) =>
      raise Failure::Failure("Expected number at async_config.linger_ms")
    None => 0
  }
  let flush = match obj.get("flush") {
    Some(Json::String(text)) => parse_async_flush(text)
    Some(_) => raise Failure::Failure("Expected string at async_config.flush")
    None => AsyncFlushPolicy::Never
  }
  AsyncLoggerConfig::new(
    max_pending~,
    overflow~,
    max_batch~,
    linger_ms~,
    flush~,
  )
}

///|
pub fn async_logger_config_to_json(config : AsyncLoggerConfig) -> Json {
  Json::object({
    "max_pending": Json::number(config.max_pending.to_double()),
    "max_batch": Json::number(config.max_batch.to_double()),
    "linger_ms": Json::number(config.linger_ms.to_double()),
    "overflow": Json::string(
      match config.overflow {
        AsyncOverflowPolicy::Blocking => "Blocking"
        AsyncOverflowPolicy::DropOldest => "DropOldest"
        AsyncOverflowPolicy::DropNewest => "DropNewest"
      },
    ),
    "flush": Json::string(
      match config.flush {
        AsyncFlushPolicy::Never => "Never"
        AsyncFlushPolicy::Batch => "Batch"
        AsyncFlushPolicy::Shutdown => "Shutdown"
      },
    ),
  })
}

///|
pub fn stringify_async_logger_config(
  config : AsyncLoggerConfig,
  pretty? : Bool = false,
) -> String {
  let value = async_logger_config_to_json(config)
  if pretty {
    value.stringify(indent=2)
  } else {
    value.stringify()
  }
}

///|
pub struct AsyncLoggerBuildConfig {
  logger : @bitlogger.LoggerConfig
  async_config : AsyncLoggerConfig
}

///|
pub fn AsyncLoggerBuildConfig::new(
  logger? : @bitlogger.LoggerConfig = @bitlogger.default_logger_config(),
  async_config? : AsyncLoggerConfig = AsyncLoggerConfig::new(),
) -> AsyncLoggerBuildConfig {
  { logger, async_config }
}

///|
pub fn parse_async_logger_build_config_text(
  input : String,
) -> AsyncLoggerBuildConfig raise {
  let root = @json.parse(input)
  let obj = match root {
    Json::Object(obj) => obj
    _ =>
      raise Failure::Failure(
        "Expected object at async logger build config root",
      )
  }
  let logger = match obj.get("logger") {
    Some(value) => @bitlogger.parse_logger_config_text(value.stringify())
    None => @bitlogger.default_logger_config()
  }
  let async_config = match obj.get("async_config") {
    Some(value) => parse_async_logger_config_text(value.stringify())
    None => AsyncLoggerConfig::new()
  }
  AsyncLoggerBuildConfig::new(logger~, async_config~)
}

///|
pub fn async_logger_build_config_to_json(
  config : AsyncLoggerBuildConfig,
) -> Json {
  Json::object({
    "logger": @bitlogger.logger_config_to_json(config.logger),
    "async_config": async_logger_config_to_json(config.async_config),
  })
}

///|
pub fn stringify_async_logger_build_config(
  config : AsyncLoggerBuildConfig,
  pretty? : Bool = false,
) -> String {
  let value = async_logger_build_config_to_json(config)
  if pretty {
    value.stringify(indent=2)
  } else {
    value.stringify()
  }
}
