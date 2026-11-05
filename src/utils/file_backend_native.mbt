///|
/// Logical file state; operations own and close their OS descriptor.
pub struct FileHandle {
  priv path : String
  priv append : Bool
  priv initialized : Ref[Bool]
  priv position : Ref[Int64]
  priv closed : Ref[Bool]
}

///|
#cfg(not(platform="windows"))
#borrow(path)
extern "C" fn open_native(path : Bytes, flags : Int32, mode : Int32) -> Int32 = "open"

///|
#cfg(platform="windows")
#borrow(path)
extern "C" fn open_native_windows(
  path : String,
  flags : Int32,
  mode : Int32,
) -> Int32 = "_wopen"

///|
#cfg(not(platform="windows"))
extern "C" fn close_native(fd : Int32) -> Int32 = "close"

///|
#cfg(platform="windows")
extern "C" fn close_native(fd : Int32) -> Int32 = "_close"

///|
#cfg(not(platform="windows"))
#borrow(content)
extern "C" fn write_native(
  fd : Int32,
  content : Bytes,
  length : UInt64,
) -> Int64 = "write"

///|
#cfg(platform="windows")
#borrow(content)
extern "C" fn write_native_windows(
  fd : Int32,
  content : Bytes,
  length : UInt32,
) -> Int32 = "_write"

///|
#cfg(not(platform="windows"))
extern "C" fn seek_native(fd : Int32, offset : Int64, whence : Int32) -> Int64 = "lseek"

///|
#cfg(platform="windows")
extern "C" fn seek_native(fd : Int32, offset : Int64, whence : Int32) -> Int64 = "_lseeki64"

///|
#cfg(not(platform="windows"))
#borrow(path)
extern "C" fn stat_native(path : Bytes) -> Int32 = "moonbit_stat_ffi"

///|
#cfg(platform="windows")
#borrow(path)
extern "C" fn access_native_windows(path : String, mode : Int32) -> Int32 = "_waccess"

///|
#cfg(not(platform="windows"))
#borrow(path)
extern "C" fn remove_native(path : Bytes) -> Int32 = "moonbit_remove_file_ffi"

///|
#cfg(platform="windows")
#borrow(path)
extern "C" fn remove_native_windows(path : String) -> Int32 = "_wremove"

///|
#cfg(not(platform="windows"))
#borrow(from_path, to_path)
extern "C" fn rename_native(from_path : Bytes, to_path : Bytes) -> Int32 = "rename"

///|
#cfg(platform="windows")
#borrow(from_path, to_path)
extern "C" fn rename_native_windows(
  from_path : String,
  to_path : String,
  flags : UInt32,
) -> Int32 = "MoveFileExW"

///|
#cfg(platform="windows")
fn open_path_internal(
  path : String,
  append : Bool,
  truncate : Bool,
  create~ : Bool = true,
  read_only~ : Bool = false,
) -> Int32 {
  open_native_windows(
    path + "\u0000",
    (if read_only { 0 } else { 1 }) |
    (if create { 256 } else { 0 }) |
    32768 |
    (if append { 8 } else { 0 }) |
    (if truncate { 512 } else { 0 }),
    384,
  )
}

///|
/// `@utf8.encode` returns exactly `length()` bytes with no trailing zero, but
/// the C file APIs take a NUL-terminated `const char *`. Copy into a buffer
/// that carries the terminator explicitly; relying on adjacent heap bytes
/// happens to work on Linux and reads garbage on macOS.
#cfg(not(platform="windows"))
fn c_path_internal(path : String) -> Bytes {
  let encoded = @utf8.encode(path)
  let length = encoded.length()
  let terminated : FixedArray[Byte] = FixedArray::make(length + 1, b'\x00')
  for index = 0; index < length; {
    terminated[index] = encoded[index]
    continue index + 1
  }
  terminated.unsafe_reinterpret_as_bytes()
}

///|
/// POSIX open flags come from the C stub so O_CREAT/O_TRUNC/O_APPEND keep their
/// real per-platform values instead of being guessed per target.
#cfg(not(platform="windows"))
extern "C" fn open_flags_internal(
  read_only : Int32,
  create : Int32,
  append : Int32,
  truncate : Int32,
) -> Int32 = "moonbit_bitlogger_open_flags"

///|
#cfg(not(platform="windows"))
extern "C" fn create_mode_internal() -> Int32 = "moonbit_bitlogger_create_mode"

///|
#cfg(not(platform="windows"))
fn open_path_internal(
  path : String,
  append : Bool,
  truncate : Bool,
  create~ : Bool = true,
  read_only~ : Bool = false,
) -> Int32 {
  open_native(
    c_path_internal(path),
    open_flags_internal(
      if read_only {
        1
      } else {
        0
      },
      if create {
        1
      } else {
        0
      },
      if append {
        1
      } else {
        0
      },
      if truncate {
        1
      } else {
        0
      },
    ),
    create_mode_internal(),
  )
}

///|
pub fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  let fd = open_path_internal(path, append, !append)
  if fd < 0 {
    None
  } else if close_native(fd) != 0 {
    None
  } else {
    Some(new_file_handle_internal(path, append, true))
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
#cfg(not(platform="windows"))
fn write_bytes_internal(fd : Int32, content : Bytes) -> Int64 {
  write_native(fd, content, content.length().to_uint64())
}

///|
#cfg(platform="windows")
fn write_bytes_internal(fd : Int32, content : Bytes) -> Int64 {
  write_native_windows(fd, content, content.length().reinterpret_as_uint()).to_int64()
}

///|
pub fn write_file_handle_internal(
  handle : FileHandle,
  content : String,
) -> Bool {
  if handle.closed.val {
    return false
  }
  let fd = open_path_internal(
    handle.path,
    handle.append,
    !handle.initialized.val && !handle.append,
  )
  if fd < 0 {
    return false
  }
  let positioned = handle.append ||
    seek_native(fd, handle.position.val, 0) >= 0L
  let bytes = @utf8.encode(content)
  let mut offset = 0
  let mut wrote = positioned
  while wrote && offset < bytes.length() {
    // The common path passes the original bytes without copying. A short
    // syscall write resumes only its remaining suffix on the same descriptor.
    let remaining = if offset == 0 { bytes } else { bytes[offset:].to_owned() }
    let count = write_bytes_internal(fd, remaining)
    if count <= 0L {
      wrote = false
    } else {
      offset = offset + count.to_int()
    }
  }
  let closed = close_native(fd) == 0
  if wrote && closed {
    if !handle.append {
      handle.position.val += bytes.length().to_int64()
    }
    handle.initialized.val = true
    true
  } else {
    false
  }
}

///|
#cfg(not(platform="windows"))
pub fn file_exists_internal(path : String) -> Bool {
  stat_native(c_path_internal(path)) == 0
}

///|
#cfg(platform="windows")
pub fn file_exists_internal(path : String) -> Bool {
  access_native_windows(path + "\u0000", 0) == 0
}

///|
pub fn flush_file_handle_internal(handle : FileHandle) -> Bool {
  // Writes close their descriptor; this is not an fsync durability request.
  !handle.closed.val
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
pub fn file_size_i64_internal(handle : FileHandle) -> Int64 {
  if handle.closed.val {
    return 0L
  }
  // Size probes never create a missing path.
  let fd = open_path_internal(
    handle.path,
    false,
    false,
    create=false,
    read_only=true,
  )
  if fd < 0 {
    return 0L
  }
  let size = seek_native(fd, 0L, 2)
  let closed = close_native(fd) == 0
  if size >= 0L && closed {
    size
  } else {
    0L
  }
}

///|
#cfg(not(platform="windows"))
pub fn rename_file_internal(from_path : String, to_path : String) -> Bool {
  rename_native(c_path_internal(from_path), c_path_internal(to_path)) == 0
}

///|
#cfg(platform="windows")
pub fn rename_file_internal(from_path : String, to_path : String) -> Bool {
  rename_native_windows(from_path + "\u0000", to_path + "\u0000", 1U) != 0
}

///|
#cfg(not(platform="windows"))
pub fn remove_file_internal(path : String) -> Bool {
  !file_exists_internal(path) || remove_native(c_path_internal(path)) == 0
}

///|
#cfg(platform="windows")
pub fn remove_file_internal(path : String) -> Bool {
  !file_exists_internal(path) || remove_native_windows(path + "\u0000") == 0
}

///|
pub fn string_byte_length_internal(content : String) -> Int32 {
  @utf8.encode(content).length()
}

///|
pub fn native_files_supported_internal() -> Bool {
  true
}
