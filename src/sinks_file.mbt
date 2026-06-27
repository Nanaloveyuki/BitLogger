///|
pub struct FileSink {
  path : String
  append : Ref[Bool]
  default_append : Bool
  handle : Ref[FileHandle?]
  formatter : RecordFormatter
  auto_flush : Ref[Bool]
  default_auto_flush : Bool
  rotation : Ref[FileRotation?]
  default_rotation : FileRotation?
  open_failures : Ref[Int]
  write_failures : Ref[Int]
  flush_failures : Ref[Int]
  rotation_failures : Ref[Int]
}

///|
pub type FileRotation = @utils.FileRotation

///|
pub type FileSinkState = @utils.FileSinkState

///|
pub type FileSinkPolicy = @utils.FileSinkPolicy

///|
pub fn file_rotation(max_bytes : Int, max_backups? : Int = 1) -> FileRotation {
  @utils.file_rotation(max_bytes, max_backups~)
}

///|
pub fn native_files_supported() -> Bool {
  native_files_supported_internal()
}

///|
pub fn file_sink(
  path : String,
  append? : Bool = true,
  auto_flush? : Bool = true,
  rotation? : FileRotation? = None,
  formatter? : RecordFormatter = fn(rec) { format_text(rec) },
) -> FileSink {
  let handle = open_file_handle_internal(path, append)
  {
    path,
    append: Ref(append),
    default_append: append,
    handle: Ref(handle),
    formatter,
    auto_flush: Ref(auto_flush),
    default_auto_flush: auto_flush,
    rotation: Ref(rotation),
    default_rotation: rotation,
    open_failures: Ref(if handle is Some(_) { 0 } else { 1 }),
    write_failures: Ref(0),
    flush_failures: Ref(0),
    rotation_failures: Ref(0),
  }
}

///|
pub fn FileSink::is_available(self : FileSink) -> Bool {
  self.handle.val is Some(_)
}

///|
pub fn FileSink::flush(self : FileSink) -> Bool {
  match self.handle.val {
    None => false
    Some(handle) => {
      let ok = flush_file_handle_internal(handle)
      if !ok {
        self.flush_failures.val += 1
      }
      ok
    }
  }
}

///|
pub fn FileSink::append_mode(self : FileSink) -> Bool {
  self.append.val
}

///|
pub fn FileSink::set_append_mode(self : FileSink, append : Bool) -> Unit {
  self.append.val = append
}

///|
pub fn FileSink::path(self : FileSink) -> String {
  self.path
}

///|
pub fn FileSink::auto_flush_enabled(self : FileSink) -> Bool {
  self.auto_flush.val
}

///|
pub fn FileSink::rotation_enabled(self : FileSink) -> Bool {
  self.rotation.val is Some(_)
}

///|
pub fn FileSink::rotation_config(self : FileSink) -> FileRotation? {
  self.rotation.val
}

///|
pub fn FileSink::set_auto_flush(self : FileSink, enabled : Bool) -> Unit {
  self.auto_flush.val = enabled
}

///|
pub fn FileSink::set_policy(self : FileSink, policy : FileSinkPolicy) -> Unit {
  self.append.val = policy.append
  self.auto_flush.val = policy.auto_flush
  self.rotation.val = policy.rotation
}

///|
pub fn FileSink::set_rotation(
  self : FileSink,
  rotation : FileRotation?,
) -> Unit {
  self.rotation.val = rotation
}

///|
pub fn FileSink::clear_rotation(self : FileSink) -> Unit {
  self.rotation.val = None
}

///|
pub fn FileSink::close(self : FileSink) -> Bool {
  match self.handle.val {
    None => false
    Some(handle) => {
      let ok = close_file_handle_internal(handle)
      self.handle.val = None
      ok
    }
  }
}

///|
pub fn FileSink::rotation_failures(self : FileSink) -> Int {
  self.rotation_failures.val
}

///|
pub fn FileSink::open_failures(self : FileSink) -> Int {
  self.open_failures.val
}

///|
pub fn FileSink::write_failures(self : FileSink) -> Int {
  self.write_failures.val
}

///|
pub fn FileSink::flush_failures(self : FileSink) -> Int {
  self.flush_failures.val
}

///|
pub fn FileSink::reset_failure_counters(self : FileSink) -> Unit {
  self.open_failures.val = 0
  self.write_failures.val = 0
  self.flush_failures.val = 0
  self.rotation_failures.val = 0
}

///|
pub fn FileSink::reset_policy(self : FileSink) -> Unit {
  self.append.val = self.default_append
  self.auto_flush.val = self.default_auto_flush
  self.rotation.val = self.default_rotation
}

///|
pub fn FileSink::policy(self : FileSink) -> FileSinkPolicy {
  FileSinkPolicy::new(
    append=self.append.val,
    auto_flush=self.auto_flush.val,
    rotation=self.rotation.val,
  )
}

///|
pub fn FileSink::default_policy(self : FileSink) -> FileSinkPolicy {
  FileSinkPolicy::new(
    append=self.default_append,
    auto_flush=self.default_auto_flush,
    rotation=self.default_rotation,
  )
}

///|
pub fn FileSink::policy_matches_default(self : FileSink) -> Bool {
  let current = self.policy()
  let default = self.default_policy()
  current.append == default.append &&
  current.auto_flush == default.auto_flush &&
  policy_rotation_equals_internal(current.rotation, default.rotation)
}

///|
fn policy_rotation_equals_internal(
  left : FileRotation?,
  right : FileRotation?,
) -> Bool {
  match (left, right) {
    (None, None) => true
    (Some(a), Some(b)) =>
      a.max_bytes == b.max_bytes && a.max_backups == b.max_backups
    _ => false
  }
}

///|
pub fn FileSink::state(self : FileSink) -> FileSinkState {
  FileSinkState::new(
    self.path,
    available=self.is_available(),
    append=self.append.val,
    auto_flush=self.auto_flush.val,
    rotation=self.rotation.val,
    open_failures=self.open_failures.val,
    write_failures=self.write_failures.val,
    flush_failures=self.flush_failures.val,
    rotation_failures=self.rotation_failures.val,
  )
}

///|
pub fn FileSink::reopen(self : FileSink, append? : Bool? = None) -> Bool {
  let append_mode = append.unwrap_or(self.append.val)
  self.append.val = append_mode
  match self.handle.val {
    None => ()
    Some(handle) => {
      ignore(close_file_handle_internal(handle))
      self.handle.val = None
    }
  }
  let reopened = open_file_handle_internal(self.path, append_mode)
  self.handle.val = reopened
  if reopened is Some(_) {
    true
  } else {
    self.open_failures.val += 1
    false
  }
}

///|
pub fn FileSink::reopen_with_current_policy(self : FileSink) -> Bool {
  self.reopen()
}

///|
pub fn FileSink::reopen_append(self : FileSink) -> Bool {
  self.reopen(append=Some(true))
}

///|
pub fn FileSink::reopen_truncate(self : FileSink) -> Bool {
  self.reopen(append=Some(false))
}

///|
fn rotated_file_path(path : String, index : Int) -> String {
  "\{path}.\{index}"
}

///|
fn rotate_file_sink_internal(sink : FileSink, rotation : FileRotation) -> Bool {
  let closed = match sink.handle.val {
    None => true
    Some(handle) => {
      let ok = close_file_handle_internal(handle)
      sink.handle.val = None
      ok
    }
  }
  if !closed {
    return false
  }
  if rotation.max_backups > 0 {
    ignore(
      remove_file_internal(rotated_file_path(sink.path, rotation.max_backups)),
    )
    for index = rotation.max_backups - 1; index >= 1; {
      let from_path = rotated_file_path(sink.path, index)
      let to_path = rotated_file_path(sink.path, index + 1)
      ignore(rename_file_internal(from_path, to_path))
      continue index - 1
    }
    ignore(rename_file_internal(sink.path, rotated_file_path(sink.path, 1)))
  } else {
    ignore(remove_file_internal(sink.path))
  }
  sink.handle.val = open_file_handle_internal(sink.path, false)
  sink.handle.val is Some(_)
}

///|
fn rotate_if_needed_internal(sink : FileSink, next_line_bytes : Int) -> Bool {
  match sink.rotation.val {
    None => true
    Some(rotation) =>
      match sink.handle.val {
        None => false
        Some(handle) => {
          let size = file_size_internal(handle)
          if size + next_line_bytes <= rotation.max_bytes {
            true
          } else {
            let rotated = rotate_file_sink_internal(sink, rotation)
            if !rotated {
              sink.rotation_failures.val += 1
            }
            rotated
          }
        }
      }
  }
}

///|
pub impl Sink for FileSink with fn write(self, rec) {
  match self.handle.val {
    None => self.write_failures.val += 1
    Some(_) => {
      let line = "\{(self.formatter)(rec)}\n"
      let can_write = rotate_if_needed_internal(
        self,
        string_byte_length_internal(line),
      )
      if can_write {
        match self.handle.val {
          None => self.write_failures.val += 1
          Some(active) => {
            let wrote = write_file_handle_internal(active, line)
            if wrote {
              if self.auto_flush.val {
                let flushed = flush_file_handle_internal(active)
                if !flushed {
                  self.flush_failures.val += 1
                }
              }
            } else {
              self.write_failures.val += 1
            }
          }
        }
      } else {
        self.write_failures.val += 1
      }
    }
  }
}
