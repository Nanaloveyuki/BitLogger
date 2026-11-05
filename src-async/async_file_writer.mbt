///|
async fn remove_file_if_present_async_internal(path : String) -> Bool {
  if !file_exists_async_internal(path) {
    true
  } else {
    remove_file_async_internal(path) || !file_exists_async_internal(path)
  }
}

///|
async fn rename_file_if_present_async_internal(
  from_path : String,
  to_path : String,
) -> Bool {
  if !file_exists_async_internal(from_path) {
    true
  } else {
    rename_file_async_internal(from_path, to_path) ||
    !file_exists_async_internal(from_path)
  }
}

///|
/// Opens a deferred handle through the async backend before its first write.
/// A deferred handle holds no descriptor yet, so this is the point where an
/// open failure becomes observable: it is counted as an open failure and the
/// unusable handle is cleared instead of being reported as a write failure.
async fn ensure_async_handle_internal(sink : @file_runtime.FileSink) -> Bool {
  match sink.handle_internal() {
    None => false
    Some(handle) =>
      if @file_utils.file_handle_is_closed_internal(handle) {
        false
      } else if @file_utils.file_handle_is_initialized_internal(handle) {
        true
      } else {
        match
          open_file_handle_async_internal(
            @file_utils.file_handle_path_internal(handle),
            @file_utils.file_handle_append_internal(handle),
          ) {
          Some(opened) => {
            sink.set_handle_internal(Some(opened))
            true
          }
          None => {
            sink.set_handle_internal(None)
            sink.record_open_failure_internal()
            false
          }
        }
      }
  }
}

///|
async fn rotate_file_sink_async_internal(
  sink : @file_runtime.FileSink,
  rotation : @bitlogger.FileRotation,
) -> Bool {
  let closed = match sink.handle_internal() {
    None => true
    Some(handle) => {
      let ok = @file_utils.close_file_handle_internal(handle)
      sink.set_handle_internal(None)
      ok
    }
  }
  if !closed {
    return false
  }
  let path = sink.path()
  if rotation.max_backups > 0 {
    if !remove_file_if_present_async_internal(
        @file_runtime.rotated_file_path(path, rotation.max_backups),
      ) {
      return false
    }
    for index = rotation.max_backups - 1; index >= 1; {
      let from_path = @file_runtime.rotated_file_path(path, index)
      let to_path = @file_runtime.rotated_file_path(path, index + 1)
      if !rename_file_if_present_async_internal(from_path, to_path) {
        return false
      }
      continue index - 1
    }
    if !rename_file_if_present_async_internal(
        path,
        @file_runtime.rotated_file_path(path, 1),
      ) {
      return false
    }
  } else if !remove_file_if_present_async_internal(path) {
    return false
  }
  sink.set_handle_internal(open_file_handle_async_internal(path, false))
  sink.handle_internal() is Some(_)
}

///|
async fn rotate_if_needed_async_internal(
  sink : @file_runtime.FileSink,
  next_line_bytes : Int32,
) -> Bool {
  match sink.rotation_internal() {
    None => true
    Some(rotation) =>
      match sink.handle_internal() {
        None => false
        Some(handle) => {
          let size = file_size_i64_async_internal(handle)
          if size + next_line_bytes.to_int64() <=
            @file_runtime.rotation_limit_bytes_internal(rotation) {
            true
          } else {
            let rotated = rotate_file_sink_async_internal(sink, rotation)
            if !rotated {
              sink.record_rotation_failure_internal()
            }
            rotated
          }
        }
      }
  }
}

///|
/// Async write path: async rotation and size probe, async bounded open, async
/// write, then an optional async flush. Mirrors the synchronous writer, with
/// the extra lazy open for deferred handles.
async fn write_file_sink_async_internal(
  sink : @file_runtime.FileSink,
  rec : @bitlogger.Record,
) -> Unit {
  match sink.handle_internal() {
    None => sink.record_write_failure_internal()
    Some(_) => {
      let line = sink.format_line_internal(rec)
      if rotate_if_needed_async_internal(
          sink,
          @file_utils.string_byte_length_internal(line),
        ) {
        if !ensure_async_handle_internal(sink) {
          sink.record_write_failure_internal()
        } else {
          match sink.handle_internal() {
            None => sink.record_write_failure_internal()
            Some(active) =>
              if write_file_handle_async_internal(active, line) {
                if sink.auto_flush_internal() {
                  if !flush_file_handle_async_internal(active) {
                    sink.record_flush_failure_internal()
                  }
                }
              } else {
                sink.record_write_failure_internal()
              }
          }
        }
      } else {
        sink.record_write_failure_internal()
      }
    }
  }
}

///|
/// Async flush. A deferred handle that has never been written holds no data,
/// so it succeeds without touching the filesystem.
async fn flush_file_sink_async_internal(sink : @file_runtime.FileSink) -> Bool {
  match sink.handle_internal() {
    None => false
    Some(handle) =>
      if @file_utils.file_handle_is_closed_internal(handle) {
        sink.record_flush_failure_internal()
        false
      } else if !@file_utils.file_handle_is_initialized_internal(handle) {
        true
      } else if flush_file_handle_async_internal(handle) {
        true
      } else {
        sink.record_flush_failure_internal()
        false
      }
  }
}
