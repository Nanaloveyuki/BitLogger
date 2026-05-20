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
