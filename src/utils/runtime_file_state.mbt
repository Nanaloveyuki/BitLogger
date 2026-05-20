pub struct RuntimeFileState {
  file : FileSinkState
  queued : Bool
  pending_count : Int
  dropped_count : Int
}

pub fn RuntimeFileState::new(
  file : FileSinkState,
  queued~ : Bool = false,
  pending_count~ : Int = 0,
  dropped_count~ : Int = 0,
) -> RuntimeFileState {
  { file, queued, pending_count, dropped_count }
}

fn file_sink_policy_to_json_value(policy : FileSinkPolicy) -> @json_parser.JsonValue {
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

pub fn file_sink_policy_to_json(policy : FileSinkPolicy) -> @json_parser.JsonValue {
  file_sink_policy_to_json_value(policy)
}

pub fn stringify_file_sink_policy(policy : FileSinkPolicy, pretty~ : Bool = false) -> String {
  let value = file_sink_policy_to_json_value(policy)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

fn file_sink_state_to_json_value(state : FileSinkState) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "path": @json_parser.JsonValue::String(state.path),
    "available": @json_parser.JsonValue::Bool(state.available),
    "append": @json_parser.JsonValue::Bool(state.append),
    "auto_flush": @json_parser.JsonValue::Bool(state.auto_flush),
    "open_failures": @json_parser.JsonValue::Number(state.open_failures.to_double()),
    "write_failures": @json_parser.JsonValue::Number(state.write_failures.to_double()),
    "flush_failures": @json_parser.JsonValue::Number(state.flush_failures.to_double()),
    "rotation_failures": @json_parser.JsonValue::Number(state.rotation_failures.to_double()),
  }
  match state.rotation {
    None => obj["rotation"] = @json_parser.JsonValue::Null
    Some(rotation) => obj["rotation"] = file_rotation_config_to_json(rotation)
  }
  @json_parser.JsonValue::Object(obj)
}

pub fn file_sink_state_to_json(state : FileSinkState) -> @json_parser.JsonValue {
  file_sink_state_to_json_value(state)
}

pub fn stringify_file_sink_state(state : FileSinkState, pretty~ : Bool = false) -> String {
  let value = file_sink_state_to_json_value(state)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

pub fn runtime_file_state_to_json(state : RuntimeFileState) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "file": file_sink_state_to_json_value(state.file),
    "queued": @json_parser.JsonValue::Bool(state.queued),
    "pending_count": @json_parser.JsonValue::Number(state.pending_count.to_double()),
    "dropped_count": @json_parser.JsonValue::Number(state.dropped_count.to_double()),
  })
}

pub fn stringify_runtime_file_state(state : RuntimeFileState, pretty~ : Bool = false) -> String {
  let value = runtime_file_state_to_json(state)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}
