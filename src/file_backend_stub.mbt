pub struct FileHandle {
  path : String
}

fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  ignore(append)
  ignore(path)
  let _unused : FileHandle = { path: "" }
  ignore(_unused)
  None
}

fn write_file_handle_internal(handle : FileHandle, content : String) -> Bool {
  ignore(handle)
  ignore(content)
  false
}

fn flush_file_handle_internal(handle : FileHandle) -> Bool {
  ignore(handle)
  false
}

fn close_file_handle_internal(handle : FileHandle) -> Bool {
  ignore(handle)
  false
}

fn file_size_internal(handle : FileHandle) -> Int {
  ignore(handle)
  0
}

fn rename_file_internal(from_path : String, to_path : String) -> Bool {
  ignore(from_path)
  ignore(to_path)
  false
}

fn remove_file_internal(path : String) -> Bool {
  ignore(path)
  false
}

fn string_byte_length_internal(content : String) -> Int {
  content.length()
}

fn native_files_supported_internal() -> Bool {
  false
}
