///|
pub type RuntimeSink = @runtime.RuntimeSink

///|
pub type RuntimeFileState = @file_model.RuntimeFileState

///|
pub type RuntimeSinkProgress = @runtime.RuntimeSinkProgress

///|
pub fn runtime_file_state_to_json(state : RuntimeFileState) -> Json {
  @file_model.runtime_file_state_to_json(state)
}

///|
pub fn stringify_runtime_file_state(
  state : RuntimeFileState,
  pretty? : Bool = false,
) -> String {
  @file_model.stringify_runtime_file_state(state, pretty~)
}

///|
pub type ConfiguredLogger = Logger[RuntimeSink]

///|
pub fn Logger::flush_progress(
  self : Logger[RuntimeSink],
) -> RuntimeSinkProgress {
  @runtime.RuntimeSink::flush_progress(self.sink)
}

///|
pub fn Logger::flush(self : Logger[RuntimeSink]) -> Int {
  @runtime.RuntimeSink::flush(self.sink)
}

///|
pub fn Logger::drain_progress(
  self : Logger[RuntimeSink],
  max_items? : Int = -1,
) -> RuntimeSinkProgress {
  @runtime.RuntimeSink::drain_progress(self.sink, max_items~)
}

///|
pub fn Logger::drain(self : Logger[RuntimeSink], max_items? : Int = -1) -> Int {
  @runtime.RuntimeSink::drain(self.sink, max_items~)
}

///|
pub fn Logger::close(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::close(self.sink)
}

///|
pub fn Logger::pending_count(self : Logger[RuntimeSink]) -> Int {
  @runtime.RuntimeSink::pending_count(self.sink)
}

///|
pub fn Logger::dropped_count(self : Logger[RuntimeSink]) -> Int {
  @runtime.RuntimeSink::dropped_count(self.sink)
}

///|
pub fn build_logger(config : LoggerConfig) -> Logger[RuntimeSink] {
  let sink = @runtime.build_runtime_sink(config.sink)
  let actual_sink = match config.queue {
    None => sink
    Some(queue) => @runtime.apply_queue_config(sink, queue)
  }
  Logger::new(actual_sink, min_level=config.min_level, target=config.target).with_timestamp(
    enabled=config.timestamp,
  )
}

///|
pub fn parse_and_build_logger(
  input : String,
) -> Logger[RuntimeSink] raise ConfigError {
  build_logger(parse_logger_config_text(input))
}
