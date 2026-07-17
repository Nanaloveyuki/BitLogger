///|
test "file sink tracks rotation failures on unavailable backend" {
  let path = "logs/bitlogger-rotate.log"
  ignore(@utils.remove_file_internal(path))
  ignore(@utils.remove_file_internal(path + ".1"))
  let sink = file_sink(path, rotation=Some(file_rotation(1, max_backups=1)))
  sink.write(record(Level::Info, "a"))
  if sink.is_available() {
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.write_failures(), content="0")
    ignore(sink.close())
    ignore(@utils.remove_file_internal(path))
    ignore(@utils.remove_file_internal(path + ".1"))
  } else {
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.write_failures(), content="1")
  }
}

///|
test "file sink reopen and failure counters reflect backend state" {
  let sink = file_sink("logs/bitlogger-reopen.log")
  if sink.is_available() {
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="0")
    inspect(sink.close(), content="true")
    inspect(sink.reopen_append(), content="true")
    inspect(sink.is_available(), content="true")
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="0")
    sink.write(record(Level::Info, "reopened"))
    inspect(sink.write_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.reopen_truncate(), content="true")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen(), content="true")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen_with_current_policy(), content="true")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen_append(), content="true")
    inspect(sink.append_mode(), content="true")
    sink.reset_failure_counters()
    inspect(sink.open_failures(), content="0")
    inspect(sink.write_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.close(), content="true")
    ignore(@utils.remove_file_internal("logs/bitlogger-reopen.log"))
  } else {
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="1")
    sink.write(record(Level::Info, "dropped"))
    inspect(sink.write_failures(), content="1")
    inspect(sink.reopen_append(), content="false")
    inspect(sink.open_failures(), content="2")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.reopen_truncate(), content="false")
    inspect(sink.append_mode(), content="false")
    inspect(sink.reopen_with_current_policy(), content="false")
    inspect(sink.open_failures(), content="4")
    inspect(sink.reopen_append(), content="false")
    inspect(sink.append_mode(), content="true")
    inspect(sink.open_failures(), content="5")
    sink.reset_failure_counters()
    inspect(sink.open_failures(), content="0")
    inspect(sink.write_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.rotation_failures(), content="0")
  }
}

///|
test "file sink can rotate on native backend" {
  let path = "logs/bitlogger-rotate-native.log"
  ignore(@utils.remove_file_internal(path))
  ignore(@utils.remove_file_internal(path + ".1"))
  ignore(@utils.remove_file_internal(path + ".2"))
  let sink = file_sink(
    path,
    auto_flush=true,
    rotation=Some(file_rotation(20, max_backups=2)),
    formatter=fn(rec) { rec.message },
  )
  if sink.is_available() {
    sink.write(record(Level::Info, "1234567890"))
    sink.write(record(Level::Info, "abcdefghij"))
    let current = @utils.open_file_handle_internal(path, true)
    let rotated = @utils.open_file_handle_internal(path + ".1", true)
    inspect(current is Some(_), content="true")
    inspect(rotated is Some(_), content="true")
    match current {
      None => ()
      Some(handle) => ignore(@utils.close_file_handle_internal(handle))
    }
    match rotated {
      None => ()
      Some(handle) => ignore(@utils.close_file_handle_internal(handle))
    }
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.close(), content="true")
    ignore(@utils.remove_file_internal(path))
    ignore(@utils.remove_file_internal(path + ".1"))
    ignore(@utils.remove_file_internal(path + ".2"))
  } else {
    inspect(sink.rotation_failures(), content="0")
  }
}
