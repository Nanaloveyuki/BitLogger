///|
pub fn Logger::file_available(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_available(self.sink)
}

///|
pub fn Logger::file_reopen(
  self : Logger[RuntimeSink],
  append? : Bool? = None,
) -> Bool {
  @runtime.RuntimeSink::file_reopen(self.sink, append~)
}

///|
pub fn Logger::file_reopen_with_current_policy(
  self : Logger[RuntimeSink],
) -> Bool {
  @runtime.RuntimeSink::file_reopen_with_current_policy(self.sink)
}

///|
pub fn Logger::file_reopen_append(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_reopen_append(self.sink)
}

///|
pub fn Logger::file_reopen_truncate(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_reopen_truncate(self.sink)
}

///|
pub fn Logger::file_append_mode(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_append_mode(self.sink)
}

///|
pub fn Logger::file_set_append_mode(
  self : Logger[RuntimeSink],
  append : Bool,
) -> Bool {
  @runtime.RuntimeSink::file_set_append_mode(self.sink, append)
}

///|
pub fn Logger::file_path_or_none(self : Logger[RuntimeSink]) -> String? {
  @runtime.RuntimeSink::file_path_or_none(self.sink)
}

///|
pub fn Logger::file_path(self : Logger[RuntimeSink]) -> String {
  @runtime.RuntimeSink::file_path(self.sink)
}

///|
pub fn Logger::file_auto_flush(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_auto_flush(self.sink)
}

///|
pub fn Logger::file_rotation_enabled(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_rotation_enabled(self.sink)
}

///|
pub fn Logger::file_rotation_config(
  self : Logger[RuntimeSink],
) -> FileRotation? {
  @runtime.RuntimeSink::file_rotation_config(self.sink)
}

///|
pub fn Logger::file_set_auto_flush(
  self : Logger[RuntimeSink],
  enabled : Bool,
) -> Bool {
  @runtime.RuntimeSink::file_set_auto_flush(self.sink, enabled)
}

///|
pub fn Logger::file_set_policy(
  self : Logger[RuntimeSink],
  policy : FileSinkPolicy,
) -> Bool {
  @runtime.RuntimeSink::file_set_policy(self.sink, policy)
}

///|
pub fn Logger::file_set_rotation(
  self : Logger[RuntimeSink],
  rotation : FileRotation?,
) -> Bool {
  @runtime.RuntimeSink::file_set_rotation(self.sink, rotation)
}

///|
pub fn Logger::file_clear_rotation(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_clear_rotation(self.sink)
}

///|
pub fn Logger::file_flush(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_flush(self.sink)
}

///|
pub fn Logger::file_close(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_close(self.sink)
}

///|
pub fn Logger::file_open_failures(self : Logger[RuntimeSink]) -> Int {
  @runtime.RuntimeSink::file_open_failures(self.sink)
}

///|
pub fn Logger::file_write_failures(self : Logger[RuntimeSink]) -> Int {
  @runtime.RuntimeSink::file_write_failures(self.sink)
}

///|
pub fn Logger::file_flush_failures(self : Logger[RuntimeSink]) -> Int {
  @runtime.RuntimeSink::file_flush_failures(self.sink)
}

///|
pub fn Logger::file_rotation_failures(self : Logger[RuntimeSink]) -> Int {
  @runtime.RuntimeSink::file_rotation_failures(self.sink)
}

///|
pub fn Logger::file_reset_failure_counters(
  self : Logger[RuntimeSink],
) -> Bool {
  @runtime.RuntimeSink::file_reset_failure_counters(self.sink)
}

///|
pub fn Logger::file_reset_policy(self : Logger[RuntimeSink]) -> Bool {
  @runtime.RuntimeSink::file_reset_policy(self.sink)
}

///|
pub fn Logger::file_policy_or_none(
  self : Logger[RuntimeSink],
) -> FileSinkPolicy? {
  @runtime.RuntimeSink::file_policy_or_none(self.sink)
}

///|
pub fn Logger::file_policy(self : Logger[RuntimeSink]) -> FileSinkPolicy {
  @runtime.RuntimeSink::file_policy(self.sink)
}

///|
pub fn Logger::file_default_policy_or_none(
  self : Logger[RuntimeSink],
) -> FileSinkPolicy? {
  @runtime.RuntimeSink::file_default_policy_or_none(self.sink)
}

///|
pub fn Logger::file_default_policy(
  self : Logger[RuntimeSink],
) -> FileSinkPolicy {
  @runtime.RuntimeSink::file_default_policy(self.sink)
}

///|
pub fn Logger::file_policy_matches_default(
  self : Logger[RuntimeSink],
) -> Bool {
  @runtime.RuntimeSink::file_policy_matches_default(self.sink)
}

///|
pub fn Logger::file_state_or_none(
  self : Logger[RuntimeSink],
) -> FileSinkState? {
  @runtime.RuntimeSink::file_state_or_none(self.sink)
}

///|
pub fn Logger::file_state(self : Logger[RuntimeSink]) -> FileSinkState {
  @runtime.RuntimeSink::file_state(self.sink)
}

///|
pub fn Logger::file_runtime_state(
  self : Logger[RuntimeSink],
) -> RuntimeFileState? {
  @runtime.RuntimeSink::file_runtime_state(self.sink)
}
