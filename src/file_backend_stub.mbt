pub type FileHandle = @utils.FileHandle

pub fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  @utils.open_file_handle_internal(path, append)
}

pub fn write_file_handle_internal(handle : FileHandle, content : String) -> Bool {
  @utils.write_file_handle_internal(handle, content)
}

pub fn flush_file_handle_internal(handle : FileHandle) -> Bool {
  @utils.flush_file_handle_internal(handle)
}

pub fn close_file_handle_internal(handle : FileHandle) -> Bool {
  @utils.close_file_handle_internal(handle)
}

pub fn file_size_internal(handle : FileHandle) -> Int {
  @utils.file_size_internal(handle)
}

pub fn rename_file_internal(from_path : String, to_path : String) -> Bool {
  @utils.rename_file_internal(from_path, to_path)
}

pub fn remove_file_internal(path : String) -> Bool {
  @utils.remove_file_internal(path)
}

pub fn string_byte_length_internal(content : String) -> Int {
  @utils.string_byte_length_internal(content)
}

pub fn native_files_supported_internal() -> Bool {
  @utils.native_files_supported_internal()
}
