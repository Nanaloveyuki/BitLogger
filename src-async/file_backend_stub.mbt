///|
type FileHandle = @file_utils.FileHandle

///|
/// Non-native targets keep the unavailable-backend behavior: every async
/// operation reports failure without touching the filesystem.
async fn open_file_handle_async_internal(
  _path : String,
  _append : Bool,
) -> FileHandle? {
  @async.pause()
  None
}

///|
async fn write_file_handle_async_internal(
  _handle : FileHandle,
  _content : String,
) -> Bool {
  @async.pause()
  false
}

///|
async fn flush_file_handle_async_internal(_handle : FileHandle) -> Bool {
  @async.pause()
  false
}

///|
async fn file_size_i64_async_internal(_handle : FileHandle) -> Int64 {
  @async.pause()
  0L
}

///|
async fn file_exists_async_internal(_path : String) -> Bool {
  @async.pause()
  false
}

///|
async fn rename_file_async_internal(
  _from_path : String,
  _to_path : String,
) -> Bool {
  @async.pause()
  false
}

///|
async fn remove_file_async_internal(_path : String) -> Bool {
  @async.pause()
  false
}
