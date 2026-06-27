///|
pub type RecordPatch = @utils.RecordPatch

///|
pub fn identity_patch() -> RecordPatch {
  @utils.identity_patch()
}

///|
pub fn set_target(target : String) -> RecordPatch {
  @utils.set_target(target)
}

///|
pub fn prefix_message(prefix : String) -> RecordPatch {
  @utils.prefix_message(prefix)
}

///|
pub fn append_fields(extra_fields : Array[Field]) -> RecordPatch {
  @utils.append_fields(extra_fields)
}

///|
pub fn redact_field(key : String, placeholder? : String = "***") -> RecordPatch {
  @utils.redact_field(key, placeholder~)
}

///|
pub fn redact_fields(
  keys : Array[String],
  placeholder? : String = "***",
) -> RecordPatch {
  @utils.redact_fields(keys, placeholder~)
}

///|
pub fn compose_patches(patches : Array[RecordPatch]) -> RecordPatch {
  @utils.compose_patches(patches)
}
