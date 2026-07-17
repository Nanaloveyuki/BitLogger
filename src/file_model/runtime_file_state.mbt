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
pub fn runtime_file_state_to_json(state : RuntimeFileState) -> Json {
  Json::object({
    "file": file_sink_state_to_json(state.file),
    "queued": Json::boolean(state.queued),
    "pending_count": Json::number(state.pending_count.to_double()),
    "dropped_count": Json::number(state.dropped_count.to_double()),
  })
}

///|
pub fn stringify_runtime_file_state(
  state : RuntimeFileState,
  pretty? : Bool = false,
) -> String {
  let value = runtime_file_state_to_json(state)
  if pretty {
    value.stringify(indent=2)
  } else {
    value.stringify()
  }
}
