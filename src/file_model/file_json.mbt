///|
pub fn file_rotation_config_to_json(
  config : FileRotation,
) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "max_bytes": @json_parser.JsonValue::Number(config.max_bytes.to_double()),
    "max_backups": @json_parser.JsonValue::Number(
      config.max_backups.to_double(),
    ),
  }
  match config.native_wide_max_bytes {
    Some(value) =>
      obj["max_bytes_i64"] = @json_parser.JsonValue::String(value.to_string())
    None => ()
  }
  @json_parser.JsonValue::Object(obj)
}

///|
pub fn file_sink_policy_to_json(
  policy : FileSinkPolicy,
) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "append": @json_parser.JsonValue::Bool(policy.append),
    "auto_flush": @json_parser.JsonValue::Bool(policy.auto_flush),
  }
  match policy.rotation {
    None => obj["rotation"] = @json_parser.JsonValue::Null
    Some(rotation) => obj["rotation"] = file_rotation_config_to_json(rotation)
  }
  @json_parser.JsonValue::Object(obj)
}

///|
pub fn stringify_file_sink_policy(
  policy : FileSinkPolicy,
  pretty? : Bool = false,
) -> String {
  let value = file_sink_policy_to_json(policy)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

///|
pub fn file_sink_state_to_json(state : FileSinkState) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "path": @json_parser.JsonValue::String(state.path),
    "available": @json_parser.JsonValue::Bool(state.available),
    "append": @json_parser.JsonValue::Bool(state.append),
    "auto_flush": @json_parser.JsonValue::Bool(state.auto_flush),
    "open_failures": @json_parser.JsonValue::Number(
      state.open_failures.to_double(),
    ),
    "write_failures": @json_parser.JsonValue::Number(
      state.write_failures.to_double(),
    ),
    "flush_failures": @json_parser.JsonValue::Number(
      state.flush_failures.to_double(),
    ),
    "rotation_failures": @json_parser.JsonValue::Number(
      state.rotation_failures.to_double(),
    ),
  }
  match state.rotation {
    None => obj["rotation"] = @json_parser.JsonValue::Null
    Some(rotation) => obj["rotation"] = file_rotation_config_to_json(rotation)
  }
  @json_parser.JsonValue::Object(obj)
}

///|
pub fn stringify_file_sink_state(
  state : FileSinkState,
  pretty? : Bool = false,
) -> String {
  let value = file_sink_state_to_json(state)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}
