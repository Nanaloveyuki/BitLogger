///|
pub(all) enum RuntimeSink {
  Console(ConsoleSink)
  JsonConsole(JsonConsoleSink)
  TextConsole(FormattedConsoleSink)
  File(FileSink)
  QueuedConsole(QueuedSink[ConsoleSink])
  QueuedJsonConsole(QueuedSink[JsonConsoleSink])
  QueuedTextConsole(QueuedSink[FormattedConsoleSink])
  QueuedFile(QueuedSink[FileSink])
}

///|
pub type RuntimeFileState = @utils.RuntimeFileState

///|
pub struct RuntimeSinkProgress {
  queue_advanced_count : Int
  file_flush_step_count : Int
  queue_backed : Bool
  file_backed : Bool
}

///|
pub fn file_sink_policy_to_json(
  policy : FileSinkPolicy,
) -> @json_parser.JsonValue {
  @utils.file_sink_policy_to_json(policy)
}

///|
pub fn stringify_file_sink_policy(
  policy : FileSinkPolicy,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_file_sink_policy(policy, pretty~)
}

///|
pub fn file_sink_state_to_json(state : FileSinkState) -> @json_parser.JsonValue {
  @utils.file_sink_state_to_json(state)
}

///|
pub fn stringify_file_sink_state(
  state : FileSinkState,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_file_sink_state(state, pretty~)
}

///|
pub fn runtime_file_state_to_json(
  state : RuntimeFileState,
) -> @json_parser.JsonValue {
  @utils.runtime_file_state_to_json(state)
}

///|
pub fn stringify_runtime_file_state(
  state : RuntimeFileState,
  pretty? : Bool = false,
) -> String {
  @utils.stringify_runtime_file_state(state, pretty~)
}

///|
pub impl Sink for RuntimeSink with fn write(self, rec) {
  match self {
    Console(sink) => sink.write(rec)
    JsonConsole(sink) => sink.write(rec)
    TextConsole(sink) => sink.write(rec)
    File(sink) => sink.write(rec)
    QueuedConsole(sink) => sink.write(rec)
    QueuedJsonConsole(sink) => sink.write(rec)
    QueuedTextConsole(sink) => sink.write(rec)
    QueuedFile(sink) => sink.write(rec)
  }
}

///|
fn[S : Sink] queued_sink_close_internal(sink : QueuedSink[S]) -> Bool {
  ignore(sink.flush())
  sink.pending_count() == 0
}

///|
fn runtime_sink_progress_compat_count(progress : RuntimeSinkProgress) -> Int {
  progress.queue_advanced_count + progress.file_flush_step_count
}

///|
pub fn RuntimeSink::flush_progress(self : RuntimeSink) -> RuntimeSinkProgress {
  match self {
    Console(_) => {
      queue_advanced_count: 0,
      file_flush_step_count: 0,
      queue_backed: false,
      file_backed: false,
    }
    JsonConsole(_) => {
      queue_advanced_count: 0,
      file_flush_step_count: 0,
      queue_backed: false,
      file_backed: false,
    }
    TextConsole(_) => {
      queue_advanced_count: 0,
      file_flush_step_count: 0,
      queue_backed: false,
      file_backed: false,
    }
    File(sink) => {
      queue_advanced_count: 0,
      file_flush_step_count: if sink.flush() { 1 } else { 0 },
      queue_backed: false,
      file_backed: true,
    }
    QueuedConsole(sink) => {
      queue_advanced_count: sink.flush(),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: false,
    }
    QueuedJsonConsole(sink) => {
      queue_advanced_count: sink.flush(),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: false,
    }
    QueuedTextConsole(sink) => {
      queue_advanced_count: sink.flush(),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: false,
    }
    QueuedFile(sink) => {
      queue_advanced_count: sink.flush(),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: true,
    }
  }
}

///|
pub fn RuntimeSink::flush(self : RuntimeSink) -> Int {
  runtime_sink_progress_compat_count(self.flush_progress())
}

///|
pub fn RuntimeSink::drain_progress(
  self : RuntimeSink,
  max_items? : Int = -1,
) -> RuntimeSinkProgress {
  match self {
    Console(_) => {
      queue_advanced_count: 0,
      file_flush_step_count: 0,
      queue_backed: false,
      file_backed: false,
    }
    JsonConsole(_) => {
      queue_advanced_count: 0,
      file_flush_step_count: 0,
      queue_backed: false,
      file_backed: false,
    }
    TextConsole(_) => {
      queue_advanced_count: 0,
      file_flush_step_count: 0,
      queue_backed: false,
      file_backed: false,
    }
    File(sink) => {
      queue_advanced_count: 0,
      file_flush_step_count: if sink.flush() { 1 } else { 0 },
      queue_backed: false,
      file_backed: true,
    }
    QueuedConsole(sink) => {
      queue_advanced_count: sink.drain(max_items~),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: false,
    }
    QueuedJsonConsole(sink) => {
      queue_advanced_count: sink.drain(max_items~),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: false,
    }
    QueuedTextConsole(sink) => {
      queue_advanced_count: sink.drain(max_items~),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: false,
    }
    QueuedFile(sink) => {
      queue_advanced_count: sink.drain(max_items~),
      file_flush_step_count: 0,
      queue_backed: true,
      file_backed: true,
    }
  }
}

///|
pub fn RuntimeSink::drain(self : RuntimeSink, max_items? : Int = -1) -> Int {
  runtime_sink_progress_compat_count(self.drain_progress(max_items~))
}

///|
pub fn RuntimeSink::close(self : RuntimeSink) -> Bool {
  match self {
    Console(_) => true
    JsonConsole(_) => true
    TextConsole(_) => true
    File(sink) => sink.close()
    QueuedConsole(sink) => queued_sink_close_internal(sink)
    QueuedJsonConsole(sink) => queued_sink_close_internal(sink)
    QueuedTextConsole(sink) => queued_sink_close_internal(sink)
    QueuedFile(sink) => queued_file_close_internal(sink)
  }
}

///|
pub fn RuntimeSink::pending_count(self : RuntimeSink) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(_) => 0
    QueuedConsole(sink) => sink.pending_count()
    QueuedJsonConsole(sink) => sink.pending_count()
    QueuedTextConsole(sink) => sink.pending_count()
    QueuedFile(sink) => sink.pending_count()
  }
}

///|
pub fn RuntimeSink::dropped_count(self : RuntimeSink) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(_) => 0
    QueuedConsole(sink) => sink.dropped_count()
    QueuedJsonConsole(sink) => sink.dropped_count()
    QueuedTextConsole(sink) => sink.dropped_count()
    QueuedFile(sink) => sink.dropped_count()
  }
}

///|
pub type ConfiguredLogger = Logger[RuntimeSink]

///|
pub fn ConfiguredLogger::flush_progress(
  self : ConfiguredLogger,
) -> RuntimeSinkProgress {
  self.sink.flush_progress()
}

///|
pub fn ConfiguredLogger::flush(self : ConfiguredLogger) -> Int {
  self.sink.flush()
}

///|
pub fn ConfiguredLogger::drain_progress(
  self : ConfiguredLogger,
  max_items? : Int = -1,
) -> RuntimeSinkProgress {
  self.sink.drain_progress(max_items~)
}

///|
pub fn ConfiguredLogger::drain(
  self : ConfiguredLogger,
  max_items? : Int = -1,
) -> Int {
  self.sink.drain(max_items~)
}

///|
pub fn ConfiguredLogger::close(self : ConfiguredLogger) -> Bool {
  self.sink.close()
}

///|
pub fn ConfiguredLogger::pending_count(self : ConfiguredLogger) -> Int {
  self.sink.pending_count()
}

///|
pub fn ConfiguredLogger::dropped_count(self : ConfiguredLogger) -> Int {
  self.sink.dropped_count()
}

///|
fn build_runtime_sink(config : SinkConfig) -> RuntimeSink {
  match config.kind {
    SinkKind::Console => RuntimeSink::Console(console_sink())
    SinkKind::JsonConsole => RuntimeSink::JsonConsole(json_console_sink())
    SinkKind::TextConsole =>
      RuntimeSink::TextConsole(
        text_console_sink(config.text_formatter.to_formatter()),
      )
    SinkKind::File =>
      RuntimeSink::File(
        file_sink(
          config.path,
          append=config.append,
          auto_flush=config.auto_flush,
          rotation=config.rotation,
          formatter=fn(rec) {
            format_text(rec, formatter=config.text_formatter.to_formatter())
          },
        ),
      )
  }
}

///|
fn apply_queue_config(sink : RuntimeSink, queue : QueueConfig) -> RuntimeSink {
  match sink {
    Console(inner) =>
      RuntimeSink::QueuedConsole(
        queued_sink(
          inner,
          max_pending=queue.max_pending,
          overflow=queue.overflow,
        ),
      )
    JsonConsole(inner) =>
      RuntimeSink::QueuedJsonConsole(
        queued_sink(
          inner,
          max_pending=queue.max_pending,
          overflow=queue.overflow,
        ),
      )
    TextConsole(inner) =>
      RuntimeSink::QueuedTextConsole(
        queued_sink(
          inner,
          max_pending=queue.max_pending,
          overflow=queue.overflow,
        ),
      )
    File(inner) =>
      RuntimeSink::QueuedFile(
        queued_sink(
          inner,
          max_pending=queue.max_pending,
          overflow=queue.overflow,
        ),
      )
    QueuedConsole(_) => sink
    QueuedJsonConsole(_) => sink
    QueuedTextConsole(_) => sink
    QueuedFile(_) => sink
  }
}

///|
pub fn build_logger(config : LoggerConfig) -> ConfiguredLogger {
  let sink = build_runtime_sink(config.sink)
  let actual_sink = match config.queue {
    None => sink
    Some(queue) => apply_queue_config(sink, queue)
  }
  Logger::new(actual_sink, min_level=config.min_level, target=config.target).with_timestamp(
    enabled=config.timestamp,
  )
}

///|
pub fn parse_and_build_logger(
  input : String,
) -> ConfiguredLogger raise ConfigError {
  build_logger(parse_logger_config_text(input))
}
