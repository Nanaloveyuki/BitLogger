///|
pub type FileSink = @file_runtime.FileSink

///|
pub type FileRotation = @file_model.FileRotation

///|
pub type FileSinkState = @file_model.FileSinkState

///|
pub type FileSinkPolicy = @file_model.FileSinkPolicy

///|
pub fn file_rotation(max_bytes : Int, max_backups? : Int = 1) -> FileRotation {
  @file_model.file_rotation(max_bytes, max_backups~)
}

///|
pub fn file_rotation_i64(
  max_bytes : Int64,
  max_backups? : Int = 1,
) -> FileRotation {
  @file_model.file_rotation_i64(max_bytes, max_backups~)
}

///|
pub fn native_files_supported() -> Bool {
  @file_runtime.native_files_supported()
}

///|
pub fn file_sink_policy_to_json(
  policy : FileSinkPolicy,
) -> @json_parser.JsonValue {
  @file_model.file_sink_policy_to_json(policy)
}

///|
pub fn stringify_file_sink_policy(
  policy : FileSinkPolicy,
  pretty? : Bool = false,
) -> String {
  @file_model.stringify_file_sink_policy(policy, pretty~)
}

///|
pub fn file_sink_state_to_json(state : FileSinkState) -> @json_parser.JsonValue {
  @file_model.file_sink_state_to_json(state)
}

///|
pub fn stringify_file_sink_state(
  state : FileSinkState,
  pretty? : Bool = false,
) -> String {
  @file_model.stringify_file_sink_state(state, pretty~)
}

///|
pub fn file_sink(
  path : String,
  append? : Bool = true,
  auto_flush? : Bool = true,
  rotation? : FileRotation? = None,
  formatter? : RecordFormatter = fn(rec) { format_text(rec) },
) -> FileSink {
  @file_runtime.file_sink(path, append~, auto_flush~, rotation~, formatter~)
}
