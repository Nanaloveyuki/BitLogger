///|
pub type RecordPatch = @record_ops.RecordPatch

///|
pub fn identity_patch() -> RecordPatch {
  @record_ops.identity_patch()
}

///|
pub fn set_target(target : String) -> RecordPatch {
  @record_ops.set_target(target)
}

///|
pub fn prefix_message(prefix : String) -> RecordPatch {
  @record_ops.prefix_message(prefix)
}

///|
pub fn append_fields(extra_fields : Array[Field]) -> RecordPatch {
  @record_ops.append_fields(extra_fields)
}

///|
pub fn redact_field(key : String, placeholder? : String = "***") -> RecordPatch {
  @record_ops.redact_field(key, placeholder~)
}

///|
pub fn redact_fields(
  keys : Array[String],
  placeholder? : String = "***",
) -> RecordPatch {
  @record_ops.redact_fields(keys, placeholder~)
}

///|
pub fn compose_patches(patches : Array[RecordPatch]) -> RecordPatch {
  @record_ops.compose_patches(patches)
}
