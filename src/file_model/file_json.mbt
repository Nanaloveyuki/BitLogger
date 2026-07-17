///|
pub fn file_rotation_config_to_json(config : FileRotation) -> Json {
  let obj : Map[String, Json] = {
    "max_bytes": Json::number(config.max_bytes.to_double()),
    "max_backups": Json::number(config.max_backups.to_double()),
  }
  match config.native_wide_max_bytes {
    Some(value) => obj["max_bytes_i64"] = Json::string(value.to_string())
    None => ()
  }
  Json::object(obj)
}

///|
pub fn file_sink_policy_to_json(policy : FileSinkPolicy) -> Json {
  let obj : Map[String, Json] = {
    "append": Json::boolean(policy.append),
    "auto_flush": Json::boolean(policy.auto_flush),
  }
  match policy.rotation {
    None => obj["rotation"] = Json::null()
    Some(rotation) => obj["rotation"] = file_rotation_config_to_json(rotation)
  }
  Json::object(obj)
}

///|
pub fn stringify_file_sink_policy(
  policy : FileSinkPolicy,
  pretty? : Bool = false,
) -> String {
  let value = file_sink_policy_to_json(policy)
  if pretty {
    value.stringify(indent=2)
  } else {
    value.stringify()
  }
}

///|
pub fn file_sink_state_to_json(state : FileSinkState) -> Json {
  let obj : Map[String, Json] = {
    "path": Json::string(state.path),
    "available": Json::boolean(state.available),
    "append": Json::boolean(state.append),
    "auto_flush": Json::boolean(state.auto_flush),
    "open_failures": Json::number(state.open_failures.to_double()),
    "write_failures": Json::number(state.write_failures.to_double()),
    "flush_failures": Json::number(state.flush_failures.to_double()),
    "rotation_failures": Json::number(state.rotation_failures.to_double()),
  }
  match state.rotation {
    None => obj["rotation"] = Json::null()
    Some(rotation) => obj["rotation"] = file_rotation_config_to_json(rotation)
  }
  Json::object(obj)
}

///|
pub fn stringify_file_sink_state(
  state : FileSinkState,
  pretty? : Bool = false,
) -> String {
  let value = file_sink_state_to_json(state)
  if pretty {
    value.stringify(indent=2)
  } else {
    value.stringify()
  }
}
