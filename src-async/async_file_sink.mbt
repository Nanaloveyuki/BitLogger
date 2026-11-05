///|
/// A file sink whose explicit async operations use the host async filesystem.
pub struct AsyncFileSink {
  priv inner : @bitlogger.FileSink
}

///|
pub async fn file_sink_async(
  path : String,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : @bitlogger.FileRotation? = None,
  formatter~ : @bitlogger.RecordFormatter = fn(rec) {
    @bitlogger.format_text(rec)
  },
) -> AsyncFileSink {
  let sink = @file_runtime.file_sink_deferred(
    path,
    append~,
    auto_flush~,
    rotation~,
    formatter~,
  )
  // A missing handle means the backend already rejected the open while the
  // deferred sink was created; only a live deferred handle still needs the
  // async open attempt, so each construction records exactly one failure.
  match sink.handle_internal() {
    None => ()
    Some(_) =>
      match open_file_handle_async_internal(path, append) {
        Some(handle) => sink.set_handle_internal(Some(handle))
        None => {
          sink.set_handle_internal(None)
          sink.record_open_failure_internal()
        }
      }
  }
  { inner: sink, }
}

///|
pub impl @bitlogger.Sink for AsyncFileSink with fn write(self, rec) {
  self.inner.write(rec)
}

///|
pub impl @bitlogger.Sink for AsyncFileSink with fn write_async(self, rec) {
  write_file_sink_async_internal(self.inner, rec)
}

///|
pub extend AsyncFileSink with @bitlogger.Sink::{write, write_async}

///|
pub async fn AsyncFileSink::flush_async(self : AsyncFileSink) -> Bool {
  flush_file_sink_async_internal(self.inner)
}

///|
pub fn AsyncFileSink::append_mode(self : AsyncFileSink) -> Bool {
  self.inner.append_mode()
}

///|
pub fn AsyncFileSink::auto_flush_enabled(self : AsyncFileSink) -> Bool {
  self.inner.auto_flush_enabled()
}

///|
pub fn AsyncFileSink::clear_rotation(self : AsyncFileSink) -> Unit {
  self.inner.clear_rotation()
}

///|
pub fn AsyncFileSink::close(self : AsyncFileSink) -> Bool {
  self.inner.close()
}

///|
pub fn AsyncFileSink::default_policy(
  self : AsyncFileSink,
) -> @bitlogger.FileSinkPolicy {
  self.inner.default_policy()
}

///|
pub fn AsyncFileSink::flush(self : AsyncFileSink) -> Bool {
  self.inner.flush()
}

///|
pub fn AsyncFileSink::flush_failures(self : AsyncFileSink) -> Int32 {
  self.inner.flush_failures()
}

///|
pub fn AsyncFileSink::is_available(self : AsyncFileSink) -> Bool {
  self.inner.is_available()
}

///|
pub fn AsyncFileSink::open_failures(self : AsyncFileSink) -> Int32 {
  self.inner.open_failures()
}

///|
pub fn AsyncFileSink::path(self : AsyncFileSink) -> String {
  self.inner.path()
}

///|
pub fn AsyncFileSink::policy(self : AsyncFileSink) -> @bitlogger.FileSinkPolicy {
  self.inner.policy()
}

///|
pub fn AsyncFileSink::policy_matches_default(self : AsyncFileSink) -> Bool {
  self.inner.policy_matches_default()
}

///|
/// Reopen is a synchronous control operation over the shared file state. It
/// installs a deferred handle, so the file is opened again by the next async
/// write rather than by this call.
pub fn AsyncFileSink::reopen(
  self : AsyncFileSink,
  append~ : Bool? = None,
) -> Bool {
  self.inner.reopen(append~)
}

///|
pub fn AsyncFileSink::reopen_append(self : AsyncFileSink) -> Bool {
  self.inner.reopen_append()
}

///|
pub fn AsyncFileSink::reopen_truncate(self : AsyncFileSink) -> Bool {
  self.inner.reopen_truncate()
}

///|
pub fn AsyncFileSink::reopen_with_current_policy(self : AsyncFileSink) -> Bool {
  self.inner.reopen_with_current_policy()
}

///|
pub fn AsyncFileSink::reset_failure_counters(self : AsyncFileSink) -> Unit {
  self.inner.reset_failure_counters()
}

///|
pub fn AsyncFileSink::reset_policy(self : AsyncFileSink) -> Unit {
  self.inner.reset_policy()
}

///|
pub fn AsyncFileSink::rotation_config(
  self : AsyncFileSink,
) -> @bitlogger.FileRotation? {
  self.inner.rotation_config()
}

///|
pub fn AsyncFileSink::rotation_enabled(self : AsyncFileSink) -> Bool {
  self.inner.rotation_enabled()
}

///|
pub fn AsyncFileSink::rotation_failures(self : AsyncFileSink) -> Int32 {
  self.inner.rotation_failures()
}

///|
pub fn AsyncFileSink::set_append_mode(
  self : AsyncFileSink,
  arg0 : Bool,
) -> Unit {
  self.inner.set_append_mode(arg0)
}

///|
pub fn AsyncFileSink::set_auto_flush(self : AsyncFileSink, arg0 : Bool) -> Unit {
  self.inner.set_auto_flush(arg0)
}

///|
pub fn AsyncFileSink::set_policy(
  self : AsyncFileSink,
  arg0 : @bitlogger.FileSinkPolicy,
) -> Unit {
  self.inner.set_policy(arg0)
}

///|
pub fn AsyncFileSink::set_rotation(
  self : AsyncFileSink,
  arg0 : @bitlogger.FileRotation?,
) -> Unit {
  self.inner.set_rotation(arg0)
}

///|
pub fn AsyncFileSink::state(self : AsyncFileSink) -> @bitlogger.FileSinkState {
  self.inner.state()
}

///|
pub fn AsyncFileSink::write_failures(self : AsyncFileSink) -> Int32 {
  self.inner.write_failures()
}
