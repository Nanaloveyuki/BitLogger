///|
type FileHandle = @file_utils.FileHandle

///|
/// Async file handles are logical: every operation opens and closes its own
/// descriptor through `moonbitlang/async/fs`, matching the synchronous backend.
async fn probe_open_file_handle_async_internal(
  path : String,
  append : Bool,
) -> Bool {
  let create_mode = if append { @fs.OpenOrCreate } else { @fs.CreateOrTruncate }
  try {
    let file = @fs.open(path, mode=@fs.WriteOnly, append~, create_mode~)
    file.close()
    true
  } catch {
    _ => false
  }
}

///|
async fn open_file_handle_async_internal(
  path : String,
  append : Bool,
) -> FileHandle? {
  if probe_open_file_handle_async_internal(path, append) {
    Some(@file_utils.new_file_handle_internal(path, append, true))
  } else {
    None
  }
}

///|
async fn write_file_handle_async_internal(
  handle : FileHandle,
  content : String,
) -> Bool {
  if @file_utils.file_handle_is_closed_internal(handle) {
    return false
  }
  let bytes = @utf8.encode(content)
  try {
    let file = @fs.open(
      @file_utils.file_handle_path_internal(handle),
      mode=@fs.WriteOnly,
      append=@file_utils.file_handle_append_internal(handle),
      create_mode=if @file_utils.file_handle_is_initialized_internal(handle) {
        @fs.OpenOrCreate
      } else if @file_utils.file_handle_append_internal(handle) {
        @fs.OpenOrCreate
      } else {
        @fs.CreateOrTruncate
      },
    )
    defer file.close()
    if @file_utils.file_handle_append_internal(handle) {
      file.write(bytes)
    } else {
      file.write_at(
        bytes[:],
        position=@file_utils.file_handle_position_internal(handle),
      )
      @file_utils.file_handle_advance_position_internal(
        handle,
        bytes.length().to_int64(),
      )
    }
    @file_utils.file_handle_set_initialized_internal(handle)
    true
  } catch {
    _ => false
  }
}

///|
async fn file_exists_async_internal(path : String) -> Bool {
  @fs.exists(path) catch {
    _ => false
  }
}

///|
async fn flush_file_handle_async_internal(handle : FileHandle) -> Bool {
  if @file_utils.file_handle_is_closed_internal(handle) {
    return false
  }
  try {
    let file = @fs.open(
      @file_utils.file_handle_path_internal(handle),
      mode=@fs.WriteOnly,
    )
    file.sync()
    file.close()
    true
  } catch {
    _ => false
  }
}

///|
async fn file_size_i64_async_internal(handle : FileHandle) -> Int64 {
  if @file_utils.file_handle_is_closed_internal(handle) {
    return 0L
  }
  try {
    let file = @fs.open(
      @file_utils.file_handle_path_internal(handle),
      mode=@fs.ReadOnly,
    )
    let size = file.size()
    file.close()
    size
  } catch {
    _ => 0L
  }
}

///|
async fn rename_file_async_internal(
  from_path : String,
  to_path : String,
) -> Bool {
  try {
    @fs.rename(from_path, to_path)
    true
  } catch {
    _ => false
  }
}

///|
async fn remove_file_async_internal(path : String) -> Bool {
  let present = @fs.exists(path) catch { _ => false }
  if present {
    try {
      @fs.remove(path)
      true
    } catch {
      _ => false
    }
  } else {
    true
  }
}
