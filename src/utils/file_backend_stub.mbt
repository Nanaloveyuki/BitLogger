///|
pub struct FileHandle {
  priv path : String
  priv append : Bool
  priv initialized : Ref[Bool]
  priv position : Ref[Int64]
  priv closed : Ref[Bool]
}

///|
pub fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  ignore(append)
  ignore(path)
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
pub fn write_file_handle_internal(
  handle : FileHandle,
  content : String,
) -> Bool {
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
pub fn string_byte_length_internal(content : String) -> Int32 {
  content.length()
}

///|
pub fn native_files_supported_internal() -> Bool {
  false
}
