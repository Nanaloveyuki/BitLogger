///|
pub type RecordPredicate = (@core.Record) -> Bool

///|
pub fn level_at_least(min_level : @core.Level) -> RecordPredicate {
  fn(rec) { rec.level.priority() >= min_level.priority() }
}

///|
pub fn target_is(target : String) -> RecordPredicate {
  fn(rec) { rec.target == target }
}

///|
pub fn target_has_prefix(prefix : String) -> RecordPredicate {
  fn(rec) { rec.target.has_prefix(prefix) }
}

///|
pub fn message_contains(fragment : String) -> RecordPredicate {
  fn(rec) { rec.message.contains(fragment) }
}

///|
pub fn has_field(key : String) -> RecordPredicate {
  fn(rec) {
    for field in rec.fields {
      if field.key == key {
        return true
      }
    }
    false
  }
}

///|
pub fn field_equals(key : String, value : String) -> RecordPredicate {
  fn(rec) {
    for field in rec.fields {
      if field.key == key && field.value == value {
        return true
      }
    }
    false
  }
}

///|
pub fn not_(predicate : RecordPredicate) -> RecordPredicate {
  fn(rec) { !predicate(rec) }
}

///|
pub fn all_of(predicates : Array[RecordPredicate]) -> RecordPredicate {
  fn(rec) {
    for predicate in predicates {
      if !predicate(rec) {
        return false
      }
    }
    true
  }
}

///|
pub fn any_of(predicates : Array[RecordPredicate]) -> RecordPredicate {
  fn(rec) {
    for predicate in predicates {
      if predicate(rec) {
        return true
      }
    }
    false
  }
}
