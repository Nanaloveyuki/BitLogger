///|
/// Configured async sink. Control operations share synchronous runtime state.
pub struct AsyncRuntimeSink {
  priv inner : @bitlogger.RuntimeSink
}

///|
pub impl @bitlogger.Sink for AsyncRuntimeSink with fn write(self, rec) {
  self.inner.write(rec)
}

///|
pub impl @bitlogger.Sink for AsyncRuntimeSink with fn write_async(self, rec) {
  match self.inner {
    @bitlogger.RuntimeSink::File(sink) =>
      write_file_sink_async_internal(sink, rec)
    _ => self.inner.write(rec)
  }
}

///|
pub extend AsyncRuntimeSink with @bitlogger.Sink::{write, write_async}

///|
pub async fn AsyncRuntimeSink::flush_async(self : AsyncRuntimeSink) -> Unit {
  match self.inner {
    @bitlogger.RuntimeSink::File(sink) =>
      ignore(flush_file_sink_async_internal(sink))
    @bitlogger.RuntimeSink::QueuedFile(queued) => {
      // Bound the batch before yielding, matching QueuedSink::drain_async.
      let limit = queued.pending_count()
      for _ in 0..<limit {
        match queued.queue.pop() {
          None => break
          Some(rec) => write_file_sink_async_internal(queued.sink, rec)
        }
      }
      ignore(flush_file_sink_async_internal(queued.sink))
    }
    _ => ignore(self.inner.flush())
  }
}

///|
pub fn AsyncRuntimeSink::kind(self : AsyncRuntimeSink) -> String {
  match self.inner {
    @bitlogger.RuntimeSink::Console(_) => "Console"
    @bitlogger.RuntimeSink::JsonConsole(_) => "JsonConsole"
    @bitlogger.RuntimeSink::TextConsole(_) => "TextConsole"
    @bitlogger.RuntimeSink::File(_) => "File"
    @bitlogger.RuntimeSink::QueuedConsole(_) => "QueuedConsole"
    @bitlogger.RuntimeSink::QueuedJsonConsole(_) => "QueuedJsonConsole"
    @bitlogger.RuntimeSink::QueuedTextConsole(_) => "QueuedTextConsole"
    @bitlogger.RuntimeSink::QueuedFile(_) => "QueuedFile"
  }
}

///|
pub fn AsyncRuntimeSink::close(self : AsyncRuntimeSink) -> Bool {
  self.inner.close()
}

///|
pub fn AsyncRuntimeSink::drain(
  self : AsyncRuntimeSink,
  max_items~ : Int32 = -1,
) -> Int32 {
  self.inner.drain(max_items~)
}

///|
pub fn AsyncRuntimeSink::drain_progress(
  self : AsyncRuntimeSink,
  max_items~ : Int32 = -1,
) -> @bitlogger.RuntimeSinkProgress {
  self.inner.drain_progress(max_items~)
}

///|
pub fn AsyncRuntimeSink::dropped_count(self : AsyncRuntimeSink) -> Int32 {
  self.inner.dropped_count()
}

///|
pub fn AsyncRuntimeSink::file_append_mode(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_append_mode()
}

///|
pub fn AsyncRuntimeSink::file_auto_flush(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_auto_flush()
}

///|
pub fn AsyncRuntimeSink::file_available(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_available()
}

///|
pub fn AsyncRuntimeSink::file_clear_rotation(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_clear_rotation()
}

///|
pub fn AsyncRuntimeSink::file_close(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_close()
}

///|
pub fn AsyncRuntimeSink::file_default_policy(
  self : AsyncRuntimeSink,
) -> @bitlogger.FileSinkPolicy {
  self.inner.file_default_policy()
}

///|
pub fn AsyncRuntimeSink::file_default_policy_or_none(
  self : AsyncRuntimeSink,
) -> @bitlogger.FileSinkPolicy? {
  self.inner.file_default_policy_or_none()
}

///|
pub fn AsyncRuntimeSink::file_flush(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_flush()
}

///|
pub fn AsyncRuntimeSink::file_flush_failures(self : AsyncRuntimeSink) -> Int32 {
  self.inner.file_flush_failures()
}

///|
pub fn AsyncRuntimeSink::file_open_failures(self : AsyncRuntimeSink) -> Int32 {
  self.inner.file_open_failures()
}

///|
pub fn AsyncRuntimeSink::file_path(self : AsyncRuntimeSink) -> String {
  self.inner.file_path()
}

///|
pub fn AsyncRuntimeSink::file_path_or_none(self : AsyncRuntimeSink) -> String? {
  self.inner.file_path_or_none()
}

///|
pub fn AsyncRuntimeSink::file_policy(
  self : AsyncRuntimeSink,
) -> @bitlogger.FileSinkPolicy {
  self.inner.file_policy()
}

///|
pub fn AsyncRuntimeSink::file_policy_matches_default(
  self : AsyncRuntimeSink,
) -> Bool {
  self.inner.file_policy_matches_default()
}

///|
pub fn AsyncRuntimeSink::file_policy_or_none(
  self : AsyncRuntimeSink,
) -> @bitlogger.FileSinkPolicy? {
  self.inner.file_policy_or_none()
}

///|
pub fn AsyncRuntimeSink::file_reopen(
  self : AsyncRuntimeSink,
  append~ : Bool? = None,
) -> Bool {
  self.inner.file_reopen(append~)
}

///|
pub fn AsyncRuntimeSink::file_reopen_append(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_reopen_append()
}

///|
pub fn AsyncRuntimeSink::file_reopen_truncate(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_reopen_truncate()
}

///|
pub fn AsyncRuntimeSink::file_reopen_with_current_policy(
  self : AsyncRuntimeSink,
) -> Bool {
  self.inner.file_reopen_with_current_policy()
}

///|
pub fn AsyncRuntimeSink::file_reset_failure_counters(
  self : AsyncRuntimeSink,
) -> Bool {
  self.inner.file_reset_failure_counters()
}

///|
pub fn AsyncRuntimeSink::file_reset_policy(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_reset_policy()
}

///|
pub fn AsyncRuntimeSink::file_rotation_config(
  self : AsyncRuntimeSink,
) -> @bitlogger.FileRotation? {
  self.inner.file_rotation_config()
}

///|
pub fn AsyncRuntimeSink::file_rotation_enabled(self : AsyncRuntimeSink) -> Bool {
  self.inner.file_rotation_enabled()
}

///|
pub fn AsyncRuntimeSink::file_rotation_failures(
  self : AsyncRuntimeSink,
) -> Int32 {
  self.inner.file_rotation_failures()
}

///|
pub fn AsyncRuntimeSink::file_runtime_state(
  self : AsyncRuntimeSink,
) -> @bitlogger.RuntimeFileState? {
  self.inner.file_runtime_state()
}

///|
pub fn AsyncRuntimeSink::file_set_append_mode(
  self : AsyncRuntimeSink,
  arg0 : Bool,
) -> Bool {
  self.inner.file_set_append_mode(arg0)
}

///|
pub fn AsyncRuntimeSink::file_set_auto_flush(
  self : AsyncRuntimeSink,
  arg0 : Bool,
) -> Bool {
  self.inner.file_set_auto_flush(arg0)
}

///|
pub fn AsyncRuntimeSink::file_set_policy(
  self : AsyncRuntimeSink,
  arg0 : @bitlogger.FileSinkPolicy,
) -> Bool {
  self.inner.file_set_policy(arg0)
}

///|
pub fn AsyncRuntimeSink::file_set_rotation(
  self : AsyncRuntimeSink,
  arg0 : @bitlogger.FileRotation?,
) -> Bool {
  self.inner.file_set_rotation(arg0)
}

///|
pub fn AsyncRuntimeSink::file_state(
  self : AsyncRuntimeSink,
) -> @bitlogger.FileSinkState {
  self.inner.file_state()
}

///|
pub fn AsyncRuntimeSink::file_state_or_none(
  self : AsyncRuntimeSink,
) -> @bitlogger.FileSinkState? {
  self.inner.file_state_or_none()
}

///|
pub fn AsyncRuntimeSink::file_write_failures(self : AsyncRuntimeSink) -> Int32 {
  self.inner.file_write_failures()
}

///|
pub fn AsyncRuntimeSink::flush(self : AsyncRuntimeSink) -> Int32 {
  self.inner.flush()
}

///|
pub fn AsyncRuntimeSink::flush_progress(
  self : AsyncRuntimeSink,
) -> @bitlogger.RuntimeSinkProgress {
  self.inner.flush_progress()
}

///|
pub fn AsyncRuntimeSink::pending_count(self : AsyncRuntimeSink) -> Int32 {
  self.inner.pending_count()
}
