pub struct FileRotation {
  max_bytes : Int
  max_backups : Int
}

pub struct FileSinkState {
  path : String
  available : Bool
  append : Bool
  auto_flush : Bool
  rotation : FileRotation?
  open_failures : Int
  write_failures : Int
  flush_failures : Int
  rotation_failures : Int
}

pub struct FileSinkPolicy {
  append : Bool
  auto_flush : Bool
  rotation : FileRotation?
}

pub fn FileSinkPolicy::new(
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
) -> FileSinkPolicy {
  { append, auto_flush, rotation }
}

pub fn FileSinkState::new(
  path : String,
  available~ : Bool = false,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  open_failures~ : Int = 0,
  write_failures~ : Int = 0,
  flush_failures~ : Int = 0,
  rotation_failures~ : Int = 0,
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

pub fn file_rotation(max_bytes : Int, max_backups~ : Int = 1) -> FileRotation {
  {
    max_bytes: if max_bytes <= 0 { 1 } else { max_bytes },
    max_backups: if max_backups <= 0 { 1 } else { max_backups },
  }
}

pub(all) enum QueueOverflowPolicy {
  DropNewest
  DropOldest
}
