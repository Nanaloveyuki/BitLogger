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

pub type RuntimeFileState = @utils.RuntimeFileState

pub fn file_sink_policy_to_json(policy : FileSinkPolicy) -> @json_parser.JsonValue {
  @utils.file_sink_policy_to_json(policy)
}

pub fn stringify_file_sink_policy(policy : FileSinkPolicy, pretty~ : Bool = false) -> String {
  @utils.stringify_file_sink_policy(policy, pretty=pretty)
}

pub fn file_sink_state_to_json(state : FileSinkState) -> @json_parser.JsonValue {
  @utils.file_sink_state_to_json(state)
}

pub fn stringify_file_sink_state(state : FileSinkState, pretty~ : Bool = false) -> String {
  @utils.stringify_file_sink_state(state, pretty=pretty)
}

pub fn runtime_file_state_to_json(state : RuntimeFileState) -> @json_parser.JsonValue {
  @utils.runtime_file_state_to_json(state)
}

pub fn stringify_runtime_file_state(state : RuntimeFileState, pretty~ : Bool = false) -> String {
  @utils.stringify_runtime_file_state(state, pretty=pretty)
}

pub impl Sink for RuntimeSink with write(self, rec) {
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

pub fn RuntimeSink::flush(self : RuntimeSink) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(sink) => if sink.flush() { 1 } else { 0 }
    QueuedConsole(sink) => sink.flush()
    QueuedJsonConsole(sink) => sink.flush()
    QueuedTextConsole(sink) => sink.flush()
    QueuedFile(sink) => sink.flush()
  }
}

pub fn RuntimeSink::drain(self : RuntimeSink, max_items~ : Int = -1) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(sink) => if sink.flush() { 1 } else { 0 }
    QueuedConsole(sink) => sink.drain(max_items=max_items)
    QueuedJsonConsole(sink) => sink.drain(max_items=max_items)
    QueuedTextConsole(sink) => sink.drain(max_items=max_items)
    QueuedFile(sink) => sink.drain(max_items=max_items)
  }
}

pub fn RuntimeSink::close(self : RuntimeSink) -> Bool {
  match self {
    Console(_) => true
    JsonConsole(_) => true
    TextConsole(_) => true
    File(sink) => sink.close()
    QueuedConsole(_) => true
    QueuedJsonConsole(_) => true
    QueuedTextConsole(_) => true
    QueuedFile(sink) => sink.sink.close()
  }
}

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

pub fn RuntimeSink::file_available(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.is_available()
    QueuedFile(sink) => sink.sink.is_available()
    _ => false
  }
}

pub fn RuntimeSink::file_reopen(self : RuntimeSink, append~ : Bool? = None) -> Bool {
  match self {
    File(sink) => sink.reopen(append=append)
    QueuedFile(sink) => sink.sink.reopen(append=append)
    _ => false
  }
}

pub fn RuntimeSink::file_reopen_with_current_policy(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.reopen_with_current_policy()
    QueuedFile(sink) => sink.sink.reopen_with_current_policy()
    _ => false
  }
}

pub fn RuntimeSink::file_reopen_append(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.reopen_append()
    QueuedFile(sink) => sink.sink.reopen_append()
    _ => false
  }
}

pub fn RuntimeSink::file_reopen_truncate(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.reopen_truncate()
    QueuedFile(sink) => sink.sink.reopen_truncate()
    _ => false
  }
}

pub fn RuntimeSink::file_append_mode(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.append_mode()
    QueuedFile(sink) => sink.sink.append_mode()
    _ => false
  }
}

pub fn RuntimeSink::file_set_append_mode(self : RuntimeSink, append : Bool) -> Bool {
  match self {
    File(sink) => {
      sink.set_append_mode(append)
      true
    }
    QueuedFile(sink) => {
      sink.sink.set_append_mode(append)
      true
    }
    _ => false
  }
}

pub fn RuntimeSink::file_path(self : RuntimeSink) -> String {
  match self {
    File(sink) => sink.path()
    QueuedFile(sink) => sink.sink.path()
    _ => ""
  }
}

pub fn RuntimeSink::file_auto_flush(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.auto_flush_enabled()
    QueuedFile(sink) => sink.sink.auto_flush_enabled()
    _ => false
  }
}

pub fn RuntimeSink::file_rotation_enabled(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.rotation_enabled()
    QueuedFile(sink) => sink.sink.rotation_enabled()
    _ => false
  }
}

pub fn RuntimeSink::file_rotation_config(self : RuntimeSink) -> FileRotation? {
  match self {
    File(sink) => sink.rotation_config()
    QueuedFile(sink) => sink.sink.rotation_config()
    _ => None
  }
}

pub fn RuntimeSink::file_set_auto_flush(self : RuntimeSink, enabled : Bool) -> Bool {
  match self {
    File(sink) => {
      sink.set_auto_flush(enabled)
      true
    }
    QueuedFile(sink) => {
      sink.sink.set_auto_flush(enabled)
      true
    }
    _ => false
  }
}

pub fn RuntimeSink::file_set_policy(self : RuntimeSink, policy : FileSinkPolicy) -> Bool {
  match self {
    File(sink) => {
      sink.set_policy(policy)
      true
    }
    QueuedFile(sink) => {
      sink.sink.set_policy(policy)
      true
    }
    _ => false
  }
}

pub fn RuntimeSink::file_set_rotation(self : RuntimeSink, rotation : FileRotation?) -> Bool {
  match self {
    File(sink) => {
      sink.set_rotation(rotation)
      true
    }
    QueuedFile(sink) => {
      sink.sink.set_rotation(rotation)
      true
    }
    _ => false
  }
}

pub fn RuntimeSink::file_clear_rotation(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => {
      sink.clear_rotation()
      true
    }
    QueuedFile(sink) => {
      sink.sink.clear_rotation()
      true
    }
    _ => false
  }
}

pub fn RuntimeSink::file_flush(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.flush()
    QueuedFile(sink) => {
      ignore(sink.flush())
      sink.sink.flush()
    }
    _ => false
  }
}

pub fn RuntimeSink::file_close(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.close()
    QueuedFile(sink) => {
      ignore(sink.flush())
      sink.sink.close()
    }
    _ => false
  }
}

pub fn RuntimeSink::file_open_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.open_failures()
    QueuedFile(sink) => sink.sink.open_failures()
    _ => 0
  }
}

pub fn RuntimeSink::file_write_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.write_failures()
    QueuedFile(sink) => sink.sink.write_failures()
    _ => 0
  }
}

pub fn RuntimeSink::file_flush_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.flush_failures()
    QueuedFile(sink) => sink.sink.flush_failures()
    _ => 0
  }
}

pub fn RuntimeSink::file_rotation_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.rotation_failures()
    QueuedFile(sink) => sink.sink.rotation_failures()
    _ => 0
  }
}

pub fn RuntimeSink::file_reset_failure_counters(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => {
      sink.reset_failure_counters()
      true
    }
    QueuedFile(sink) => {
      sink.sink.reset_failure_counters()
      true
    }
    _ => false
  }
}

pub fn RuntimeSink::file_reset_policy(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => {
      sink.reset_policy()
      true
    }
    QueuedFile(sink) => {
      sink.sink.reset_policy()
      true
    }
    _ => false
  }
}

pub fn RuntimeSink::file_policy(self : RuntimeSink) -> FileSinkPolicy {
  match self {
    File(sink) => sink.policy()
    QueuedFile(sink) => sink.sink.policy()
    _ => FileSinkPolicy::new(append=false, auto_flush=false, rotation=None)
  }
}

pub fn RuntimeSink::file_default_policy(self : RuntimeSink) -> FileSinkPolicy {
  match self {
    File(sink) => sink.default_policy()
    QueuedFile(sink) => sink.sink.default_policy()
    _ => FileSinkPolicy::new(append=false, auto_flush=false, rotation=None)
  }
}

pub fn RuntimeSink::file_policy_matches_default(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.policy_matches_default()
    QueuedFile(sink) => sink.sink.policy_matches_default()
    _ => false
  }
}

pub fn RuntimeSink::file_state(self : RuntimeSink) -> FileSinkState {
  match self {
    File(sink) => sink.state()
    QueuedFile(sink) => sink.sink.state()
    _ => FileSinkState::new(
      "",
      available=false,
      append=false,
      auto_flush=false,
      rotation=None,
      open_failures=0,
      write_failures=0,
      flush_failures=0,
      rotation_failures=0,
    )
  }
}

pub fn RuntimeSink::file_runtime_state(self : RuntimeSink) -> RuntimeFileState? {
  match self {
    File(sink) => Some(RuntimeFileState::new(sink.state()))
    QueuedFile(sink) => Some(
      RuntimeFileState::new(
        sink.sink.state(),
        queued=true,
        pending_count=sink.pending_count(),
        dropped_count=sink.dropped_count(),
      ),
    )
    _ => None
  }
}

pub type ConfiguredLogger = Logger[RuntimeSink]

pub fn ConfiguredLogger::flush(self : ConfiguredLogger) -> Int {
  self.sink.flush()
}

pub fn ConfiguredLogger::drain(self : ConfiguredLogger, max_items~ : Int = -1) -> Int {
  self.sink.drain(max_items=max_items)
}

pub fn ConfiguredLogger::close(self : ConfiguredLogger) -> Bool {
  self.sink.close()
}

pub fn ConfiguredLogger::pending_count(self : ConfiguredLogger) -> Int {
  self.sink.pending_count()
}

pub fn ConfiguredLogger::dropped_count(self : ConfiguredLogger) -> Int {
  self.sink.dropped_count()
}

pub fn ConfiguredLogger::file_available(self : ConfiguredLogger) -> Bool {
  self.sink.file_available()
}

pub fn ConfiguredLogger::file_reopen(self : ConfiguredLogger, append~ : Bool? = None) -> Bool {
  self.sink.file_reopen(append=append)
}

pub fn ConfiguredLogger::file_reopen_with_current_policy(self : ConfiguredLogger) -> Bool {
  self.sink.file_reopen_with_current_policy()
}

pub fn ConfiguredLogger::file_reopen_append(self : ConfiguredLogger) -> Bool {
  self.sink.file_reopen_append()
}

pub fn ConfiguredLogger::file_reopen_truncate(self : ConfiguredLogger) -> Bool {
  self.sink.file_reopen_truncate()
}

pub fn ConfiguredLogger::file_append_mode(self : ConfiguredLogger) -> Bool {
  self.sink.file_append_mode()
}

pub fn ConfiguredLogger::file_set_append_mode(self : ConfiguredLogger, append : Bool) -> Bool {
  self.sink.file_set_append_mode(append)
}

pub fn ConfiguredLogger::file_path(self : ConfiguredLogger) -> String {
  self.sink.file_path()
}

pub fn ConfiguredLogger::file_auto_flush(self : ConfiguredLogger) -> Bool {
  self.sink.file_auto_flush()
}

pub fn ConfiguredLogger::file_rotation_enabled(self : ConfiguredLogger) -> Bool {
  self.sink.file_rotation_enabled()
}

pub fn ConfiguredLogger::file_rotation_config(self : ConfiguredLogger) -> FileRotation? {
  self.sink.file_rotation_config()
}

pub fn ConfiguredLogger::file_set_auto_flush(self : ConfiguredLogger, enabled : Bool) -> Bool {
  self.sink.file_set_auto_flush(enabled)
}

pub fn ConfiguredLogger::file_set_policy(self : ConfiguredLogger, policy : FileSinkPolicy) -> Bool {
  self.sink.file_set_policy(policy)
}

pub fn ConfiguredLogger::file_set_rotation(
  self : ConfiguredLogger,
  rotation : FileRotation?,
) -> Bool {
  self.sink.file_set_rotation(rotation)
}

pub fn ConfiguredLogger::file_clear_rotation(self : ConfiguredLogger) -> Bool {
  self.sink.file_clear_rotation()
}

pub fn ConfiguredLogger::file_flush(self : ConfiguredLogger) -> Bool {
  self.sink.file_flush()
}

pub fn ConfiguredLogger::file_close(self : ConfiguredLogger) -> Bool {
  self.sink.file_close()
}

pub fn ConfiguredLogger::file_open_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_open_failures()
}

pub fn ConfiguredLogger::file_write_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_write_failures()
}

pub fn ConfiguredLogger::file_flush_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_flush_failures()
}

pub fn ConfiguredLogger::file_rotation_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_rotation_failures()
}

pub fn ConfiguredLogger::file_reset_failure_counters(self : ConfiguredLogger) -> Bool {
  self.sink.file_reset_failure_counters()
}

pub fn ConfiguredLogger::file_reset_policy(self : ConfiguredLogger) -> Bool {
  self.sink.file_reset_policy()
}

pub fn ConfiguredLogger::file_policy(self : ConfiguredLogger) -> FileSinkPolicy {
  self.sink.file_policy()
}

pub fn ConfiguredLogger::file_default_policy(self : ConfiguredLogger) -> FileSinkPolicy {
  self.sink.file_default_policy()
}

pub fn ConfiguredLogger::file_policy_matches_default(self : ConfiguredLogger) -> Bool {
  self.sink.file_policy_matches_default()
}

pub fn ConfiguredLogger::file_state(self : ConfiguredLogger) -> FileSinkState {
  self.sink.file_state()
}

pub fn ConfiguredLogger::file_runtime_state(self : ConfiguredLogger) -> RuntimeFileState? {
  self.sink.file_runtime_state()
}

fn build_runtime_sink(config : SinkConfig) -> RuntimeSink {
  match config.kind {
    SinkKind::Console => RuntimeSink::Console(console_sink())
    SinkKind::JsonConsole => RuntimeSink::JsonConsole(json_console_sink())
    SinkKind::TextConsole => RuntimeSink::TextConsole(
      text_console_sink(config.text_formatter.to_formatter()),
    )
    SinkKind::File => RuntimeSink::File(
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

fn apply_queue_config(sink : RuntimeSink, queue : QueueConfig) -> RuntimeSink {
  match sink {
    Console(inner) => RuntimeSink::QueuedConsole(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    JsonConsole(inner) => RuntimeSink::QueuedJsonConsole(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    TextConsole(inner) => RuntimeSink::QueuedTextConsole(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    File(inner) => RuntimeSink::QueuedFile(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    QueuedConsole(_) => sink
    QueuedJsonConsole(_) => sink
    QueuedTextConsole(_) => sink
    QueuedFile(_) => sink
  }
}

pub fn build_logger(config : LoggerConfig) -> ConfiguredLogger {
  let sink = build_runtime_sink(config.sink)
  let actual_sink = match config.queue {
    None => sink
    Some(queue) => apply_queue_config(sink, queue)
  }
  Logger::new(actual_sink, min_level=config.min_level, target=config.target)
    .with_timestamp(enabled=config.timestamp)
}

pub fn parse_and_build_logger(input : String) -> ConfiguredLogger raise ConfigError {
  build_logger(parse_logger_config_text(input))
}
