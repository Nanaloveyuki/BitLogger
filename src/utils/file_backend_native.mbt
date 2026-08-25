///|
pub struct FileHandle {
  priv path : String
  priv append : Bool
  priv initialized : Ref[Bool]
  priv position : Ref[Int64]
  priv closed : Ref[Bool]
}

///|
fn run_async_bool_internal(operation : async () -> Bool) -> Bool {
  let result = Ref(false)
  @async.run_async_main(() => result.val = operation())
  result.val
}

///|
fn run_async_i64_internal(operation : async () -> Int64) -> Int64 {
  let result = Ref(0L)
  @async.run_async_main(() => result.val = operation())
  result.val
}

///|
fn new_file_handle_internal(
  path : String,
  append : Bool,
  initialized : Bool,
) -> FileHandle {
  {
    path,
    append,
    initialized: Ref(initialized),
    position: Ref(0L),
    closed: Ref(false),
  }
}

///|
async fn probe_open_file_handle_async_internal(
  path : String,
  append : Bool,
) -> Bool {
  try {
    let create_mode = if append {
      @fs.OpenOrCreate
    } else {
      @fs.CreateOrTruncate
    }
    let file = @fs.open(path, mode=@fs.WriteOnly, append~, create_mode~)
    file.close()
    true
  } catch {
    _ => false
  }
}

///|
pub async fn open_file_handle_async_internal(
  path : String,
  append : Bool,
) -> FileHandle? {
  if probe_open_file_handle_async_internal(path, append) {
    Some(new_file_handle_internal(path, append, true))
  } else {
    None
  }
}

///|
pub fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  let opened = run_async_bool_internal(() => {
    probe_open_file_handle_async_internal(path, append)
  })
  if opened {
    Some(new_file_handle_internal(path, append, true))
  } else {
    None
  }
}

///|
pub fn deferred_file_handle_internal(
  path : String,
  append : Bool,
) -> FileHandle? {
  Some(new_file_handle_internal(path, append, false))
}

///|
pub async fn write_file_handle_async_internal(
  handle : FileHandle,
  content : String,
) -> Bool {
  if handle.closed.val {
    return false
  }
  let bytes = @utf8.encode(content)
  try {
    let file = @fs.open(
      handle.path,
      mode=@fs.WriteOnly,
      append=handle.append,
      create_mode=if handle.initialized.val {
        @fs.OpenOrCreate
      } else if handle.append {
        @fs.OpenOrCreate
      } else {
        @fs.CreateOrTruncate
      },
    )
    defer file.close()
    if handle.append {
      file.write(bytes)
    } else {
      file.write_at(bytes[:], position=handle.position.val)
      handle.position.val += bytes.length().to_int64()
    }
    handle.initialized.val = true
    true
  } catch {
    _ => false
  }
}

///|
pub fn file_exists_internal(path : String) -> Bool {
  run_async_bool_internal(() => @fs.exists(path))
}

///|
pub async fn file_exists_async_internal(path : String) -> Bool {
  @fs.exists(path) catch {
    _ => false
  }
}

///|
pub fn write_file_handle_internal(
  handle : FileHandle,
  content : String,
) -> Bool {
  run_async_bool_internal(() => {
    write_file_handle_async_internal(handle, content)
  })
}

///|
pub async fn flush_file_handle_async_internal(handle : FileHandle) -> Bool {
  if handle.closed.val {
    return false
  }
  try {
    let file = @fs.open(handle.path, mode=@fs.WriteOnly)
    file.sync()
    file.close()
    true
  } catch {
    _ => false
  }
}

///|
pub fn flush_file_handle_internal(handle : FileHandle) -> Bool {
  if handle.closed.val {
    false
  } else {
    // Each write owns and closes its File, so there is no buffered handle to flush here.
    true
  }
}

///|
pub fn close_file_handle_internal(handle : FileHandle) -> Bool {
  if handle.closed.val {
    false
  } else {
    handle.closed.val = true
    true
  }
}

///|
pub async fn file_size_i64_async_internal(handle : FileHandle) -> Int64 {
  if handle.closed.val {
    return 0L
  }
  try {
    let file = @fs.open(handle.path, mode=@fs.ReadOnly)
    let size = file.size()
    file.close()
    size
  } catch {
    _ => 0L
  }
}

///|
pub fn file_size_i64_internal(handle : FileHandle) -> Int64 {
  run_async_i64_internal(() => file_size_i64_async_internal(handle))
}

///|
pub async fn rename_file_async_internal(
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
pub fn rename_file_internal(from_path : String, to_path : String) -> Bool {
  run_async_bool_internal(() => rename_file_async_internal(from_path, to_path))
}

///|
pub async fn remove_file_async_internal(path : String) -> Bool {
  try {
    @fs.remove(path)
    true
  } catch {
    _ => false
  }
}

///|
pub fn remove_file_internal(path : String) -> Bool {
  run_async_bool_internal(() => remove_file_async_internal(path))
}

///|
pub fn string_byte_length_internal(content : String) -> Int {
  @utf8.encode(content).length()
}

///|
pub fn native_files_supported_internal() -> Bool {
  true
}
