///|
test "native file support flag is queryable" {
  inspect(
    native_files_supported() == true || native_files_supported() == false,
    content="true",
  )
}

///|
test "file sink availability reflects backend support" {
  let sink = file_sink("bitlogger-test.log")
  let state = sink.state()
  inspect(sink.path(), content="bitlogger-test.log")
  inspect(sink.is_available() == native_files_supported(), content="true")
  inspect(state.path, content="bitlogger-test.log")
  inspect(state.available == sink.is_available(), content="true")
  inspect(state.append == sink.append_mode(), content="true")
  inspect(state.auto_flush == sink.auto_flush_enabled(), content="true")
  inspect(
    (state.rotation is None) == (sink.rotation_config() is None),
    content="true",
  )
  inspect(sink.append_mode(), content="true")
  inspect(sink.auto_flush_enabled(), content="true")
  inspect(sink.rotation_enabled(), content="false")
  inspect(sink.rotation_config() is None, content="true")
  inspect(
    sink.open_failures(),
    content=if sink.is_available() { "0" } else { "1" },
  )
  inspect(sink.write_failures(), content="0")
  inspect(sink.flush_failures(), content="0")
  if sink.is_available() {
    inspect(sink.flush(), content="true")
    inspect(sink.close(), content="true")
  } else {
    inspect(sink.flush(), content="false")
    inspect(sink.close(), content="false")
  }
}

///|
test "file sink unavailable backend keeps stable fallback state" {
  let sink = file_sink(
    "bitlogger-unavailable.log",
    rotation=Some(file_rotation(64, max_backups=2)),
  )
  if sink.is_available() {
    inspect(sink.state().available, content="true")
    ignore(sink.close())
  } else {
    let state = sink.state()
    inspect(native_files_supported(), content="false")
    inspect(state.available, content="false")
    inspect(sink.flush(), content="false")
    inspect(sink.close(), content="false")
    inspect(sink.write_failures(), content="0")
    sink.write(Record::new(Level::Info, "dropped"))
    inspect(sink.write_failures(), content="1")
    inspect(sink.rotation_failures(), content="0")
    match state.rotation {
      Some(rotation) => {
        inspect(rotation.max_bytes, content="64")
        inspect(rotation.max_backups, content="2")
      }
      None => inspect(false, content="true")
    }
  }
}

///|
test "file sink rotation config normalizes invalid inputs" {
  let rotation = file_rotation(0, max_backups=0)
  inspect(rotation.max_bytes, content="1")
  inspect(rotation.max_backups, content="1")
  let sink = file_sink("bitlogger-rotation-config.log", rotation=Some(rotation))
  inspect(sink.rotation_enabled(), content="true")
  match sink.rotation_config() {
    Some(config) => {
      inspect(config.max_bytes, content="1")
      inspect(config.max_backups, content="1")
    }
    None => inspect(false, content="true")
  }
}

///|
test "file rotation i64 preserves wide threshold metadata" {
  let rotation = file_rotation_i64(4294967296L, max_backups=2)
  inspect(rotation.max_bytes, content="2147483647")
  inspect(rotation.max_backups, content="2")
  match rotation.native_wide_max_bytes {
    Some(value) => inspect(value, content="4294967296")
    None => inspect(false, content="true")
  }
}

///|
test "file sink setters update auto flush and rotation state" {
  let sink = file_sink("bitlogger-setters.log")
  let default_policy = sink.default_policy()
  inspect(sink.append_mode(), content="true")
  inspect(sink.auto_flush_enabled(), content="true")
  inspect(sink.rotation_enabled(), content="false")
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(sink.policy_matches_default(), content="true")
  sink.set_append_mode(false)
  inspect(sink.append_mode(), content="false")
  sink.set_auto_flush(false)
  inspect(sink.auto_flush_enabled(), content="false")
  sink.set_rotation(Some(file_rotation(32, max_backups=2)))
  inspect(sink.rotation_enabled(), content="true")
  match sink.rotation_config() {
    Some(config) => {
      inspect(config.max_bytes, content="32")
      inspect(config.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  sink.clear_rotation()
  inspect(sink.rotation_enabled(), content="false")
  inspect(sink.rotation_config() is None, content="true")
  inspect(
    sink.reopen(),
    content=if sink.is_available() { "true" } else { "false" },
  )
  inspect(sink.append_mode(), content="false")
  let state = sink.state()
  let policy = sink.policy()
  inspect(state.append, content="false")
  inspect(state.auto_flush, content="false")
  inspect(state.rotation is None, content="true")
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  inspect(policy.rotation is None, content="true")
  inspect(sink.policy_matches_default(), content="false")
  sink.reset_policy()
  inspect(sink.append_mode(), content="true")
  inspect(sink.auto_flush_enabled(), content="true")
  inspect(sink.rotation_config() is None, content="true")
  inspect(sink.policy_matches_default(), content="true")
}

///|
test "file sink reset policy restores configured defaults" {
  let sink = file_sink(
    "bitlogger-reset-policy.log",
    append=false,
    auto_flush=false,
    rotation=Some(file_rotation(24, max_backups=3)),
  )
  sink.set_append_mode(true)
  sink.set_auto_flush(true)
  sink.clear_rotation()
  let default_policy = sink.default_policy()
  inspect(default_policy.append, content="false")
  inspect(default_policy.auto_flush, content="false")
  inspect(sink.policy_matches_default(), content="false")
  sink.reset_policy()
  inspect(sink.append_mode(), content="false")
  inspect(sink.auto_flush_enabled(), content="false")
  inspect(sink.policy_matches_default(), content="true")
  match sink.rotation_config() {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="24")
      inspect(rotation.max_backups, content="3")
    }
    None => inspect(false, content="true")
  }
}

///|
test "file sink set policy applies bundled runtime policy" {
  let sink = file_sink("bitlogger-set-policy.log")
  let default_policy = sink.default_policy()
  sink.set_policy(
    FileSinkPolicy::new(
      append=false,
      auto_flush=false,
      rotation=Some(file_rotation(18, max_backups=2)),
    ),
  )
  let policy = sink.policy()
  inspect(policy.append, content="false")
  inspect(policy.auto_flush, content="false")
  match policy.rotation {
    Some(rotation) => {
      inspect(rotation.max_bytes, content="18")
      inspect(rotation.max_backups, content="2")
    }
    None => inspect(false, content="true")
  }
  inspect(default_policy.append, content="true")
  inspect(default_policy.auto_flush, content="true")
  inspect(default_policy.rotation is None, content="true")
  inspect(sink.policy_matches_default(), content="false")
}
