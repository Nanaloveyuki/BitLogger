///|
pub type RecordPredicate = @record_ops.RecordPredicate

///|
pub fn level_at_least(min_level : Level) -> RecordPredicate {
  @record_ops.level_at_least(min_level)
}

///|
pub fn target_is(target : String) -> RecordPredicate {
  @record_ops.target_is(target)
}

///|
pub fn target_has_prefix(prefix : String) -> RecordPredicate {
  @record_ops.target_has_prefix(prefix)
}

///|
pub fn message_contains(fragment : String) -> RecordPredicate {
  @record_ops.message_contains(fragment)
}

///|
pub fn has_field(key : String) -> RecordPredicate {
  @record_ops.has_field(key)
}

///|
pub fn field_equals(key : String, value : String) -> RecordPredicate {
  @record_ops.field_equals(key, value)
}

///|
pub fn not_(predicate : RecordPredicate) -> RecordPredicate {
  @record_ops.not_(predicate)
}

///|
pub fn all_of(predicates : Array[RecordPredicate]) -> RecordPredicate {
  @record_ops.all_of(predicates)
}

///|
pub fn any_of(predicates : Array[RecordPredicate]) -> RecordPredicate {
  @record_ops.any_of(predicates)
}
