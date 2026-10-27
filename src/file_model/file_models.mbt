///|
pub struct FileRotation {
  max_bytes : Int32
  max_backups : Int32
  native_wide_max_bytes : Int64?
}

///|
pub struct FileSinkState {
  path : String
  available : Bool
  append : Bool
  auto_flush : Bool
  rotation : FileRotation?
  open_failures : Int32
  write_failures : Int32
  flush_failures : Int32
  rotation_failures : Int32
}

///|
pub struct FileSinkPolicy {
  append : Bool
  auto_flush : Bool
  rotation : FileRotation?
}

///|
pub fn FileSinkPolicy::new(
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
) -> FileSinkPolicy {
  { append, auto_flush, rotation, }
}

///|
pub fn FileSinkState::new(
  path : String,
  available~ : Bool = false,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  open_failures~ : Int32 = 0,
  write_failures~ : Int32 = 0,
  flush_failures~ : Int32 = 0,
  rotation_failures~ : Int32 = 0,
) -> FileSinkState {
  {
    path,
    available,
    append,
    auto_flush,
    rotation,
    open_failures,
    write_failures,
    flush_failures,
    rotation_failures,
  }
}

///|
pub fn file_rotation(
  max_bytes : Int32,
  max_backups~ : Int32 = 1,
) -> FileRotation {
  {
    max_bytes: if max_bytes <= 0 {
      1
    } else {
      max_bytes
    },
    max_backups: if max_backups <= 0 {
      1
    } else {
      max_backups
    },
    native_wide_max_bytes: None,
  }
}

///|
pub fn file_rotation_i64(
  max_bytes : Int64,
  max_backups~ : Int32 = 1,
) -> FileRotation {
  let normalized = if max_bytes <= 0L { 1L } else { max_bytes }
  let clamped_max_bytes = if normalized > 2147483647L {
    2147483647
  } else {
    normalized.to_int()
  }
  {
    max_bytes: clamped_max_bytes,
    max_backups: if max_backups <= 0 {
      1
    } else {
      max_backups
    },
    native_wide_max_bytes: Some(normalized),
  }
}
