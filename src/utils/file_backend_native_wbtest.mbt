///|
/// The C file APIs read a NUL-terminated string. `@utf8.encode` returns exactly
/// `length()` bytes, so the backend must add the terminator itself.
test "c path buffers are NUL terminated and preserve UTF-8" {
  let path = "logs/同步-🌙.log"
  let raw = @utf8.encode(path)
  let terminated = c_path_internal(path)
  inspect(terminated.length(), content="\{(raw.length() + 1)}")
  inspect(terminated[raw.length()].to_int(), content="0")
  for index = 0; index < raw.length(); {
    inspect(terminated[index] == raw[index], content="true")
    continue index + 1
  }
}
