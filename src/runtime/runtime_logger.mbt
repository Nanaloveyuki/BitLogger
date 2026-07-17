///|
type SinkConfig = @config_model.SinkConfig

///|
type SinkKind = @config_model.SinkKind

///|
type QueueConfig = @config_model.QueueConfig

///|
type FileSink = @file_runtime.FileSink

///|
type FileRotation = @file_model.FileRotation

///|
type FileSinkState = @file_model.FileSinkState

///|
type FileSinkPolicy = @file_model.FileSinkPolicy

///|
type ConsoleSink = @sink_graph.ConsoleSink

///|
type JsonConsoleSink = @sink_graph.JsonConsoleSink

///|
type FormattedConsoleSink = @sink_graph.FormattedConsoleSink

///|
type QueuedSink[S] = @sink_graph.QueuedSink[S]

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
pub type RuntimeFileState = @file_model.RuntimeFileState

///|
pub struct RuntimeSinkProgress {
  queue_advanced_count : Int
  file_flush_step_count : Int
  queue_backed : Bool
  file_backed : Bool
}

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
pub impl @sink_graph.Sink for RuntimeSink with fn write(self, rec) {
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
fn[S : @sink_graph.Sink] queued_sink_close_internal(
  sink : QueuedSink[S],
) -> Bool {
  ignore(sink.flush())
  sink.pending_count() == 0
}

///|
fn runtime_file_sink_internal(sink : RuntimeSink) -> FileSink? {
  match sink {
    File(sink) => Some(sink)
    QueuedFile(sink) => Some(sink.sink)
    _ => None
  }
}

///|
fn queued_file_policy_mutation_allowed_internal(
  sink : QueuedSink[FileSink],
) -> Bool {
  sink.pending_count() == 0
}

///|
fn queued_file_flush_internal(sink : QueuedSink[FileSink]) -> Bool {
  let before_write_failures = sink.sink.write_failures()
  let before_flush_failures = sink.sink.flush_failures()
  let before_rotation_failures = sink.sink.rotation_failures()
  ignore(sink.flush())
  let flushed = sink.sink.flush()
  sink.pending_count() == 0 &&
  flushed &&
  sink.sink.write_failures() == before_write_failures &&
  sink.sink.flush_failures() == before_flush_failures &&
  sink.sink.rotation_failures() == before_rotation_failures
}

///|
fn queued_file_close_internal(sink : QueuedSink[FileSink]) -> Bool {
  let flushed = queued_file_flush_internal(sink)
  let closed = sink.sink.close()
  flushed && closed
}

///|
fn runtime_sink_progress_compat_count(progress : RuntimeSinkProgress) -> Int {
  progress.queue_advanced_count + progress.file_flush_step_count
}

///|
pub fn RuntimeSink::flush_progress(self : RuntimeSink) -> RuntimeSinkProgress {
  match self {
    Console(_) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: 0,
        queue_backed: false,
        file_backed: false,
      }
    JsonConsole(_) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: 0,
        queue_backed: false,
        file_backed: false,
      }
    TextConsole(_) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: 0,
        queue_backed: false,
        file_backed: false,
      }
    File(sink) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: if sink.flush() {
          1
        } else {
          0
        },
        queue_backed: false,
        file_backed: true,
      }
    QueuedConsole(sink) =>
      {
        queue_advanced_count: sink.flush(),
        file_flush_step_count: 0,
        queue_backed: true,
        file_backed: false,
      }
    QueuedJsonConsole(sink) =>
      {
        queue_advanced_count: sink.flush(),
        file_flush_step_count: 0,
        queue_backed: true,
        file_backed: false,
      }
    QueuedTextConsole(sink) =>
      {
        queue_advanced_count: sink.flush(),
        file_flush_step_count: 0,
        queue_backed: true,
        file_backed: false,
      }
    QueuedFile(sink) =>
      {
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
    Console(_) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: 0,
        queue_backed: false,
        file_backed: false,
      }
    JsonConsole(_) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: 0,
        queue_backed: false,
        file_backed: false,
      }
    TextConsole(_) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: 0,
        queue_backed: false,
        file_backed: false,
      }
    File(sink) =>
      {
        queue_advanced_count: 0,
        file_flush_step_count: if sink.flush() {
          1
        } else {
          0
        },
        queue_backed: false,
        file_backed: true,
      }
    QueuedConsole(sink) =>
      {
        queue_advanced_count: sink.drain(max_items~),
        file_flush_step_count: 0,
        queue_backed: true,
        file_backed: false,
      }
    QueuedJsonConsole(sink) =>
      {
        queue_advanced_count: sink.drain(max_items~),
        file_flush_step_count: 0,
        queue_backed: true,
        file_backed: false,
      }
    QueuedTextConsole(sink) =>
      {
        queue_advanced_count: sink.drain(max_items~),
        file_flush_step_count: 0,
        queue_backed: true,
        file_backed: false,
      }
    QueuedFile(sink) =>
      {
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
pub fn RuntimeSink::file_available(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.is_available()
    QueuedFile(sink) => sink.sink.is_available()
    _ => false
  }
}

///|
pub fn RuntimeSink::file_reopen(
  self : RuntimeSink,
  append? : Bool? = None,
) -> Bool {
  match self {
    File(sink) => sink.reopen(append~)
    QueuedFile(sink) =>
      if queued_file_policy_mutation_allowed_internal(sink) {
        sink.sink.reopen(append~)
      } else {
        false
      }
    _ => false
  }
}

///|
pub fn RuntimeSink::file_reopen_with_current_policy(self : RuntimeSink) -> Bool {
  self.file_reopen()
}

///|
pub fn RuntimeSink::file_reopen_append(self : RuntimeSink) -> Bool {
  self.file_reopen(append=Some(true))
}

///|
pub fn RuntimeSink::file_reopen_truncate(self : RuntimeSink) -> Bool {
  self.file_reopen(append=Some(false))
}

///|
pub fn RuntimeSink::file_append_mode(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.append_mode()
    QueuedFile(sink) => sink.sink.append_mode()
    _ => false
  }
}

///|
pub fn RuntimeSink::file_set_append_mode(
  self : RuntimeSink,
  append : Bool,
) -> Bool {
  match self {
    File(sink) => {
      sink.set_append_mode(append)
      true
    }
    QueuedFile(sink) =>
      if queued_file_policy_mutation_allowed_internal(sink) {
        sink.sink.set_append_mode(append)
        true
      } else {
        false
      }
    _ => false
  }
}

///|
pub fn RuntimeSink::file_path_or_none(self : RuntimeSink) -> String? {
  runtime_file_sink_internal(self).map(fn(sink) { sink.path() })
}

///|
pub fn RuntimeSink::file_path(self : RuntimeSink) -> String {
  self.file_path_or_none().unwrap_or("")
}

///|
pub fn RuntimeSink::file_auto_flush(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.auto_flush_enabled()
    QueuedFile(sink) => sink.sink.auto_flush_enabled()
    _ => false
  }
}

///|
pub fn RuntimeSink::file_rotation_enabled(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.rotation_enabled()
    QueuedFile(sink) => sink.sink.rotation_enabled()
    _ => false
  }
}

///|
pub fn RuntimeSink::file_rotation_config(self : RuntimeSink) -> FileRotation? {
  match self {
    File(sink) => sink.rotation_config()
    QueuedFile(sink) => sink.sink.rotation_config()
    _ => None
  }
}

///|
pub fn RuntimeSink::file_set_auto_flush(
  self : RuntimeSink,
  enabled : Bool,
) -> Bool {
  match self {
    File(sink) => {
      sink.set_auto_flush(enabled)
      true
    }
    QueuedFile(sink) =>
      if queued_file_policy_mutation_allowed_internal(sink) {
        sink.sink.set_auto_flush(enabled)
        true
      } else {
        false
      }
    _ => false
  }
}

///|
pub fn RuntimeSink::file_set_policy(
  self : RuntimeSink,
  policy : FileSinkPolicy,
) -> Bool {
  match self {
    File(sink) => {
      sink.set_policy(policy)
      true
    }
    QueuedFile(sink) =>
      if queued_file_policy_mutation_allowed_internal(sink) {
        sink.sink.set_policy(policy)
        true
      } else {
        false
      }
    _ => false
  }
}

///|
pub fn RuntimeSink::file_set_rotation(
  self : RuntimeSink,
  rotation : FileRotation?,
) -> Bool {
  match self {
    File(sink) => {
      sink.set_rotation(rotation)
      true
    }
    QueuedFile(sink) =>
      if queued_file_policy_mutation_allowed_internal(sink) {
        sink.sink.set_rotation(rotation)
        true
      } else {
        false
      }
    _ => false
  }
}

///|
pub fn RuntimeSink::file_clear_rotation(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => {
      sink.clear_rotation()
      true
    }
    QueuedFile(sink) =>
      if queued_file_policy_mutation_allowed_internal(sink) {
        sink.sink.clear_rotation()
        true
      } else {
        false
      }
    _ => false
  }
}

///|
pub fn RuntimeSink::file_flush(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.flush()
    QueuedFile(sink) => queued_file_flush_internal(sink)
    _ => false
  }
}

///|
pub fn RuntimeSink::file_close(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.close()
    QueuedFile(sink) => queued_file_close_internal(sink)
    _ => false
  }
}

///|
pub fn RuntimeSink::file_open_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.open_failures()
    QueuedFile(sink) => sink.sink.open_failures()
    _ => 0
  }
}

///|
pub fn RuntimeSink::file_write_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.write_failures()
    QueuedFile(sink) => sink.sink.write_failures()
    _ => 0
  }
}

///|
pub fn RuntimeSink::file_flush_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.flush_failures()
    QueuedFile(sink) => sink.sink.flush_failures()
    _ => 0
  }
}

///|
pub fn RuntimeSink::file_rotation_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.rotation_failures()
    QueuedFile(sink) => sink.sink.rotation_failures()
    _ => 0
  }
}

///|
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

///|
pub fn RuntimeSink::file_reset_policy(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => {
      sink.reset_policy()
      true
    }
    QueuedFile(sink) =>
      if queued_file_policy_mutation_allowed_internal(sink) {
        sink.sink.reset_policy()
        true
      } else {
        false
      }
    _ => false
  }
}

///|
pub fn RuntimeSink::file_policy_or_none(self : RuntimeSink) -> FileSinkPolicy? {
  runtime_file_sink_internal(self).map(fn(sink) { sink.policy() })
}

///|
pub fn RuntimeSink::file_policy(self : RuntimeSink) -> FileSinkPolicy {
  self
  .file_policy_or_none()
  .unwrap_or(FileSinkPolicy::new(append=false, auto_flush=false, rotation=None))
}

///|
pub fn RuntimeSink::file_default_policy_or_none(
  self : RuntimeSink,
) -> FileSinkPolicy? {
  runtime_file_sink_internal(self).map(fn(sink) { sink.default_policy() })
}

///|
pub fn RuntimeSink::file_default_policy(self : RuntimeSink) -> FileSinkPolicy {
  self
  .file_default_policy_or_none()
  .unwrap_or(FileSinkPolicy::new(append=false, auto_flush=false, rotation=None))
}

///|
pub fn RuntimeSink::file_policy_matches_default(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.policy_matches_default()
    QueuedFile(sink) => sink.sink.policy_matches_default()
    _ => false
  }
}

///|
pub fn RuntimeSink::file_state_or_none(self : RuntimeSink) -> FileSinkState? {
  runtime_file_sink_internal(self).map(fn(sink) { sink.state() })
}

///|
pub fn RuntimeSink::file_state(self : RuntimeSink) -> FileSinkState {
  self
  .file_state_or_none()
  .unwrap_or(
    FileSinkState::new(
      "",
      available=false,
      append=false,
      auto_flush=false,
      rotation=None,
      open_failures=0,
      write_failures=0,
      flush_failures=0,
      rotation_failures=0,
    ),
  )
}

///|
pub fn RuntimeSink::file_runtime_state(self : RuntimeSink) -> RuntimeFileState? {
  match self {
    File(sink) => Some(RuntimeFileState::new(sink.state()))
    QueuedFile(sink) =>
      Some(
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

///|
pub fn build_runtime_sink(config : SinkConfig) -> RuntimeSink {
  match config.kind {
    SinkKind::Console => RuntimeSink::Console(@sink_graph.console_sink())
    SinkKind::JsonConsole =>
      RuntimeSink::JsonConsole(@sink_graph.json_console_sink())
    SinkKind::TextConsole =>
      RuntimeSink::TextConsole(
        @sink_graph.text_console_sink(config.text_formatter.to_formatter()),
      )
    SinkKind::File =>
      RuntimeSink::File(
        @file_runtime.file_sink(
          config.path,
          append=config.append,
          auto_flush=config.auto_flush,
          rotation=config.rotation,
          formatter=fn(rec) {
            @formatting.format_text(
              rec,
              formatter=config.text_formatter.to_formatter(),
            )
          },
        ),
      )
  }
}

///|
pub fn apply_queue_config(
  sink : RuntimeSink,
  queue : QueueConfig,
) -> RuntimeSink {
  match sink {
    Console(inner) =>
      RuntimeSink::QueuedConsole(
        @sink_graph.queued_sink(
          inner,
          max_pending=queue.max_pending,
          overflow=queue.overflow,
        ),
      )
    JsonConsole(inner) =>
      RuntimeSink::QueuedJsonConsole(
        @sink_graph.queued_sink(
          inner,
          max_pending=queue.max_pending,
          overflow=queue.overflow,
        ),
      )
    TextConsole(inner) =>
      RuntimeSink::QueuedTextConsole(
        @sink_graph.queued_sink(
          inner,
          max_pending=queue.max_pending,
          overflow=queue.overflow,
        ),
      )
    File(inner) =>
      RuntimeSink::QueuedFile(
        @sink_graph.queued_sink(
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
