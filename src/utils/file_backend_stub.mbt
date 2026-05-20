pub struct FileHandle {
  path : String
}

pub fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  ignore(append)
  ignore(path)
  let _unused : FileHandle = { path: "" }
  ignore(_unused)
  None
}

pub fn write_file_handle_internal(handle : FileHandle, content : String) -> Bool {
  ignore(handle)
  ignore(content)
  false
}

pub fn flush_file_handle_internal(handle : FileHandle) -> Bool {
  ignore(handle)
  false
}

pub fn close_file_handle_internal(handle : FileHandle) -> Bool {
  ignore(handle)
  false
}

pub fn file_size_internal(handle : FileHandle) -> Int {
  ignore(handle)
  0
}

pub fn rename_file_internal(from_path : String, to_path : String) -> Bool {
  ignore(from_path)
  ignore(to_path)
  false
}

pub fn remove_file_internal(path : String) -> Bool {
  ignore(path)
  false
}

pub fn string_byte_length_internal(content : String) -> Int {
  content.length()
}

pub fn native_files_supported_internal() -> Bool {
  false
}
