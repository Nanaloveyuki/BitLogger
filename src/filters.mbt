///|
pub type RecordPredicate = @utils.RecordPredicate

///|
pub fn level_at_least(min_level : Level) -> RecordPredicate {
  @utils.level_at_least(min_level)
}

///|
pub fn target_is(target : String) -> RecordPredicate {
  @utils.target_is(target)
}

///|
pub fn target_has_prefix(prefix : String) -> RecordPredicate {
  @utils.target_has_prefix(prefix)
}

///|
pub fn message_contains(fragment : String) -> RecordPredicate {
  @utils.message_contains(fragment)
}

///|
pub fn has_field(key : String) -> RecordPredicate {
  @utils.has_field(key)
}

///|
pub fn field_equals(key : String, value : String) -> RecordPredicate {
  @utils.field_equals(key, value)
}

///|
pub fn not_(predicate : RecordPredicate) -> RecordPredicate {
  @utils.not_(predicate)
}

///|
pub fn all_of(predicates : Array[RecordPredicate]) -> RecordPredicate {
  @utils.all_of(predicates)
}

///|
pub fn any_of(predicates : Array[RecordPredicate]) -> RecordPredicate {
  @utils.any_of(predicates)
}
