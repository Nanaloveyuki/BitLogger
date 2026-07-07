///|
pub struct RuntimeFileState {
  file : FileSinkState
  queued : Bool
  pending_count : Int
  dropped_count : Int
}

///|
pub fn RuntimeFileState::new(
  file : FileSinkState,
  queued? : Bool = false,
  pending_count? : Int = 0,
  dropped_count? : Int = 0,
) -> RuntimeFileState {
  { file, queued, pending_count, dropped_count }
}

///|
pub fn runtime_file_state_to_json(
  state : RuntimeFileState,
) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "file": file_sink_state_to_json(state.file),
    "queued": @json_parser.JsonValue::Bool(state.queued),
    "pending_count": @json_parser.JsonValue::Number(
      state.pending_count.to_double(),
    ),
    "dropped_count": @json_parser.JsonValue::Number(
      state.dropped_count.to_double(),
    ),
  })
}

///|
pub fn stringify_runtime_file_state(
  state : RuntimeFileState,
  pretty? : Bool = false,
) -> String {
  let value = runtime_file_state_to_json(state)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}
