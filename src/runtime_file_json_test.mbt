///|
test "file state json helpers stringify stable snapshots" {
  let rotation_json = file_rotation_config_to_json(
    file_rotation(64, max_backups=2),
  )
  let rotation_obj = rotation_json.expect_json_object()
  inspect(
    rotation_json.stringify(),
    content="{\"max_bytes\":64,\"max_backups\":2}",
  )
  inspect(
    rotation_obj.get("max_bytes").unwrap().expect_json_number().to_int(),
    content="64",
  )
  inspect(
    rotation_obj.get("max_backups").unwrap().expect_json_number().to_int(),
    content="2",
  )
  inspect(rotation_obj.get("max_bytes_i64") is None, content="true")

  let wide_rotation_json = file_rotation_config_to_json(
    file_rotation_i64(4294967296L, max_backups=2),
  )
  let wide_rotation_obj = wide_rotation_json.expect_json_object()
  inspect(
    wide_rotation_obj.get("max_bytes_i64").unwrap().expect_json_string(),
    content="4294967296",
  )

  let plain = file_sink_state_to_json(
    FileSinkState::new(
      "logs/demo.log",
      available=true,
      append=false,
      auto_flush=true,
      rotation=Some(file_rotation(64, max_backups=2)),
      open_failures=1,
      write_failures=2,
      flush_failures=3,
      rotation_failures=4,
    ),
  )
  let plain_obj = plain.expect_json_object()
  let plain_rotation_obj = plain_obj
    .get("rotation")
    .unwrap()
    .expect_json_object()
  inspect(
    plain.stringify(),
    content="{\"path\":\"logs/demo.log\",\"available\":true,\"append\":false,\"auto_flush\":true,\"open_failures\":1,\"write_failures\":2,\"flush_failures\":3,\"rotation_failures\":4,\"rotation\":{\"max_bytes\":64,\"max_backups\":2}}",
  )
  inspect(
    plain_obj.get("path").unwrap().expect_json_string(),
    content="logs/demo.log",
  )
  inspect(
    plain_obj.get("available").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(plain_obj.get("append").unwrap().expect_json_bool(), content="false")
  inspect(
    plain_obj.get("auto_flush").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    plain_obj.get("open_failures").unwrap().expect_json_number().to_int(),
    content="1",
  )
  inspect(
    plain_obj.get("write_failures").unwrap().expect_json_number().to_int(),
    content="2",
  )
  inspect(
    plain_obj.get("flush_failures").unwrap().expect_json_number().to_int(),
    content="3",
  )
  inspect(
    plain_obj.get("rotation_failures").unwrap().expect_json_number().to_int(),
    content="4",
  )
  inspect(
    plain_rotation_obj.get("max_bytes").unwrap().expect_json_number().to_int(),
    content="64",
  )
  inspect(
    plain_rotation_obj.get("max_backups").unwrap().expect_json_number().to_int(),
    content="2",
  )

  let wide = file_sink_state_to_json(
    FileSinkState::new(
      "logs/wide.log",
      available=true,
      append=true,
      auto_flush=false,
      rotation=Some(file_rotation_i64(4294967296L, max_backups=3)),
      open_failures=0,
      write_failures=0,
      flush_failures=0,
      rotation_failures=0,
    ),
  )
  let wide_obj = wide.expect_json_object()
  let wide_state_rotation_obj = wide_obj
    .get("rotation")
    .unwrap()
    .expect_json_object()
  inspect(
    wide_state_rotation_obj
    .get("max_bytes")
    .unwrap()
    .expect_json_number()
    .to_int(),
    content="2147483647",
  )
  inspect(
    wide_state_rotation_obj
    .get("max_backups")
    .unwrap()
    .expect_json_number()
    .to_int(),
    content="3",
  )
  inspect(
    wide_state_rotation_obj.get("max_bytes_i64").unwrap().expect_json_string(),
    content="4294967296",
  )
  inspect(
    stringify_file_sink_state(
      FileSinkState::new(
        "logs/plain.log",
        available=false,
        append=true,
        auto_flush=false,
        rotation=None,
        open_failures=0,
        write_failures=0,
        flush_failures=0,
        rotation_failures=0,
      ),
    ),
    content="{\"path\":\"logs/plain.log\",\"available\":false,\"append\":true,\"auto_flush\":false,\"open_failures\":0,\"write_failures\":0,\"flush_failures\":0,\"rotation_failures\":0,\"rotation\":null}",
  )
}

///|
test "runtime file state json helpers stringify queue snapshots" {
  let runtime_json = runtime_file_state_to_json(
    RuntimeFileState::new(
      FileSinkState::new(
        "logs/queue.log",
        available=true,
        append=true,
        auto_flush=false,
        rotation=None,
        open_failures=0,
        write_failures=1,
        flush_failures=2,
        rotation_failures=3,
      ),
      queued=true,
      pending_count=7,
      dropped_count=5,
    ),
  )
  let runtime_obj = runtime_json.expect_json_object()
  let runtime_file_obj = runtime_obj.get("file").unwrap().expect_json_object()
  inspect(runtime_obj.get("queued").unwrap().expect_json_bool(), content="true")
  inspect(
    runtime_obj.get("pending_count").unwrap().expect_json_number().to_int(),
    content="7",
  )
  inspect(
    runtime_obj.get("dropped_count").unwrap().expect_json_number().to_int(),
    content="5",
  )
  inspect(
    runtime_file_obj.get("path").unwrap().expect_json_string(),
    content="logs/queue.log",
  )
  inspect(
    runtime_file_obj.get("available").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    runtime_file_obj.get("rotation").unwrap() is Json::Null,
    content="true",
  )

  let json = stringify_runtime_file_state(
    RuntimeFileState::new(
      FileSinkState::new(
        "logs/queue.log",
        available=true,
        append=true,
        auto_flush=false,
        rotation=None,
        open_failures=0,
        write_failures=1,
        flush_failures=2,
        rotation_failures=3,
      ),
      queued=true,
      pending_count=7,
      dropped_count=5,
    ),
  )
  inspect(
    json,
    content="{\"file\":{\"path\":\"logs/queue.log\",\"available\":true,\"append\":true,\"auto_flush\":false,\"open_failures\":0,\"write_failures\":1,\"flush_failures\":2,\"rotation_failures\":3,\"rotation\":null},\"queued\":true,\"pending_count\":7,\"dropped_count\":5}",
  )

  let wide_runtime_json = runtime_file_state_to_json(
    RuntimeFileState::new(
      FileSinkState::new(
        "logs/wide-queue.log",
        available=true,
        append=true,
        auto_flush=true,
        rotation=Some(file_rotation_i64(4294967296L, max_backups=2)),
        open_failures=0,
        write_failures=0,
        flush_failures=0,
        rotation_failures=0,
      ),
      queued=false,
      pending_count=0,
      dropped_count=0,
    ),
  )
  let wide_runtime_obj = wide_runtime_json.expect_json_object()
  let wide_runtime_file_obj = wide_runtime_obj
    .get("file")
    .unwrap()
    .expect_json_object()
  let wide_runtime_rotation_obj = wide_runtime_file_obj
    .get("rotation")
    .unwrap()
    .expect_json_object()
  inspect(
    wide_runtime_rotation_obj
    .get("max_bytes")
    .unwrap()
    .expect_json_number()
    .to_int(),
    content="2147483647",
  )
  inspect(
    wide_runtime_rotation_obj
    .get("max_backups")
    .unwrap()
    .expect_json_number()
    .to_int(),
    content="2",
  )
  inspect(
    wide_runtime_rotation_obj.get("max_bytes_i64").unwrap().expect_json_string(),
    content="4294967296",
  )
}

///|
test "file sink policy json helpers stringify stable policies" {
  let policy_json = file_sink_policy_to_json(
    FileSinkPolicy::new(
      append=false,
      auto_flush=true,
      rotation=Some(file_rotation(96, max_backups=3)),
    ),
  )
  let policy_obj = policy_json.expect_json_object()
  let policy_rotation_obj = policy_obj
    .get("rotation")
    .unwrap()
    .expect_json_object()
  inspect(
    policy_json.stringify(),
    content="{\"append\":false,\"auto_flush\":true,\"rotation\":{\"max_bytes\":96,\"max_backups\":3}}",
  )
  inspect(policy_obj.get("append").unwrap().expect_json_bool(), content="false")
  inspect(
    policy_obj.get("auto_flush").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    policy_rotation_obj.get("max_bytes").unwrap().expect_json_number().to_int(),
    content="96",
  )
  inspect(
    policy_rotation_obj
    .get("max_backups")
    .unwrap()
    .expect_json_number()
    .to_int(),
    content="3",
  )

  let wide_policy_json = file_sink_policy_to_json(
    FileSinkPolicy::new(
      append=true,
      auto_flush=false,
      rotation=Some(file_rotation_i64(4294967296L, max_backups=4)),
    ),
  )
  let wide_policy_obj = wide_policy_json.expect_json_object()
  let wide_policy_rotation_obj = wide_policy_obj
    .get("rotation")
    .unwrap()
    .expect_json_object()
  inspect(
    wide_policy_rotation_obj
    .get("max_bytes")
    .unwrap()
    .expect_json_number()
    .to_int(),
    content="2147483647",
  )
  inspect(
    wide_policy_rotation_obj
    .get("max_backups")
    .unwrap()
    .expect_json_number()
    .to_int(),
    content="4",
  )
  inspect(
    wide_policy_rotation_obj.get("max_bytes_i64").unwrap().expect_json_string(),
    content="4294967296",
  )
  inspect(
    stringify_file_sink_policy(
      FileSinkPolicy::new(append=true, auto_flush=false, rotation=None),
    ),
    content="{\"append\":true,\"auto_flush\":false,\"rotation\":null}",
  )
}
