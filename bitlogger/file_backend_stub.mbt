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

fn native_files_supported_internal() -> Bool {
  false
}
