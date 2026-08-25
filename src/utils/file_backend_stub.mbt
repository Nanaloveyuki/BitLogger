///|
pub struct FileHandle {
  priv dummy : Unit
}

///|
pub fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  ignore(append)
  ignore(path)
  let _unused : FileHandle = { dummy: () }
  ignore(_unused)
  None
}

///|
pub fn deferred_file_handle_internal(
  path : String,
  append : Bool,
) -> FileHandle? {
  ignore(append)
  ignore(path)
  None
}

///|
pub fn file_exists_internal(path : String) -> Bool {
  ignore(path)
  false
}

///|
async fn stub_async_noop_internal() -> Unit {
  ignore(@fs.unimplemented)
  @async.pause()
}

///|
pub async fn open_file_handle_async_internal(
  path : String,
  append : Bool,
) -> FileHandle? {
  stub_async_noop_internal()
  ignore(append)
  ignore(path)
  None
}

///|
pub async fn file_exists_async_internal(path : String) -> Bool {
  stub_async_noop_internal()
  ignore(path)
  false
}

///|
pub async fn write_file_handle_async_internal(
  handle : FileHandle,
  content : String,
) -> Bool {
  stub_async_noop_internal()
  ignore(handle)
  ignore(content)
  false
}

///|
pub async fn flush_file_handle_async_internal(handle : FileHandle) -> Bool {
  stub_async_noop_internal()
  ignore(handle)
  false
}

///|
pub async fn file_size_i64_async_internal(handle : FileHandle) -> Int64 {
  stub_async_noop_internal()
  ignore(handle)
  0L
}

///|
pub async fn rename_file_async_internal(
  from_path : String,
  to_path : String,
) -> Bool {
  stub_async_noop_internal()
  ignore(from_path)
  ignore(to_path)
  false
}

///|
pub async fn remove_file_async_internal(path : String) -> Bool {
  stub_async_noop_internal()
  ignore(path)
  false
}

///|
pub fn write_file_handle_internal(
  handle : FileHandle,
  content : String,
) -> Bool {
  ignore(handle.dummy)
  ignore(handle)
  ignore(content)
  false
}

///|
pub fn flush_file_handle_internal(handle : FileHandle) -> Bool {
  ignore(handle)
  false
}

///|
pub fn close_file_handle_internal(handle : FileHandle) -> Bool {
  ignore(handle)
  false
}

///|
pub fn file_size_i64_internal(handle : FileHandle) -> Int64 {
  ignore(handle)
  0L
}

///|
pub fn rename_file_internal(from_path : String, to_path : String) -> Bool {
  ignore(from_path)
  ignore(to_path)
  false
}

///|
pub fn remove_file_internal(path : String) -> Bool {
  ignore(path)
  false
}

///|
pub fn string_byte_length_internal(content : String) -> Int {
  content.length()
}

///|
pub fn native_files_supported_internal() -> Bool {
  false
}
