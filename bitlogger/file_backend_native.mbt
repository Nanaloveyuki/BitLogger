fn string_to_c_bytes(str : String) -> Bytes {
  let res : Array[Byte] = []
  let len = str.length()
  let mut i = 0
  while i < len {
    let mut c = str.code_unit_at(i).to_int()
    if 0xD800 <= c && c <= 0xDBFF {
      c -= 0xD800
      i = i + 1
      let l = str.code_unit_at(i).to_int() - 0xDC00
      c = (c << 10) + l + 0x10000
    }
    if c < 0x80 {
      res.push(c.to_byte())
    } else if c < 0x800 {
      res.push((0xc0 + (c >> 6)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else if c < 0x10000 {
      res.push((0xe0 + (c >> 12)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else {
      res.push((0xf0 + (c >> 18)).to_byte())
      res.push((0x80 + ((c >> 12) & 0x3f)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    }
    i = i + 1
  }
  res.push((0).to_byte())
  Bytes::from_array(res)
}

#external
type NativeFileHandle

#borrow(path, mode)
extern "C" fn file_open_ffi(path : Bytes, mode : Bytes) -> NativeFileHandle = "fopen"

extern "C" fn file_is_null_ffi(handle : NativeFileHandle) -> Bool = "moonbitlang_async_pointer_is_null"

#borrow(buffer)
extern "C" fn file_write_ffi(
  buffer : Bytes,
  size : Int,
  count : Int,
  handle : NativeFileHandle,
) -> Int = "fwrite"

extern "C" fn file_flush_ffi(handle : NativeFileHandle) -> Int = "fflush"

extern "C" fn file_close_ffi(handle : NativeFileHandle) -> Int = "fclose"

pub struct FileHandle {
  path : String
  raw : NativeFileHandle
}

fn open_file_handle_internal(path : String, append : Bool) -> FileHandle? {
  let mode = if append { "ab" } else { "wb" }
  let raw = file_open_ffi(string_to_c_bytes(path), string_to_c_bytes(mode))
  if file_is_null_ffi(raw) {
    None
  } else {
    Some({ raw, path })
  }
}

fn write_file_handle_internal(handle : FileHandle, content : String) -> Bool {
  let bytes = string_to_c_bytes(content)
  let written = file_write_ffi(bytes, 1, bytes.length() - 1, handle.raw)
  written == bytes.length() - 1
}

fn flush_file_handle_internal(handle : FileHandle) -> Bool {
  file_flush_ffi(handle.raw) == 0
}

fn close_file_handle_internal(handle : FileHandle) -> Bool {
  file_close_ffi(handle.raw) == 0
}

fn native_files_supported_internal() -> Bool {
  true
}
