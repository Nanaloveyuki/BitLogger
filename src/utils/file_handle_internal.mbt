///|
#doc(hidden)
pub fn new_file_handle_internal(
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
#doc(hidden)
pub fn file_handle_path_internal(handle : FileHandle) -> String {
  handle.path
}

///|
#doc(hidden)
pub fn file_handle_append_internal(handle : FileHandle) -> Bool {
  handle.append
}

///|
#doc(hidden)
pub fn file_handle_is_closed_internal(handle : FileHandle) -> Bool {
  handle.closed.val
}

///|
#doc(hidden)
pub fn file_handle_is_initialized_internal(handle : FileHandle) -> Bool {
  handle.initialized.val
}

///|
#doc(hidden)
pub fn file_handle_set_initialized_internal(handle : FileHandle) -> Unit {
  handle.initialized.val = true
}

///|
#doc(hidden)
pub fn file_handle_position_internal(handle : FileHandle) -> Int64 {
  handle.position.val
}

///|
#doc(hidden)
pub fn file_handle_advance_position_internal(
  handle : FileHandle,
  byte_count : Int64,
) -> Unit {
  handle.position.val += byte_count
}
