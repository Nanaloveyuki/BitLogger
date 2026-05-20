pub type RecordPatch = (@core.Record) -> @core.Record

pub fn identity_patch() -> RecordPatch {
  fn(rec) { rec }
}

pub fn set_target(target : String) -> RecordPatch {
  fn(rec) {
    rec.with_target(target)
  }
}

pub fn prefix_message(prefix : String) -> RecordPatch {
  fn(rec) {
    rec.with_message("\{prefix}\{rec.message}")
  }
}

pub fn append_fields(extra_fields : Array[@core.Field]) -> RecordPatch {
  fn(rec) {
    if extra_fields.length() == 0 {
      rec
    } else if rec.fields.length() == 0 {
      rec.with_fields(extra_fields)
    } else {
      rec.with_fields(rec.fields + extra_fields)
    }
  }
}

pub fn redact_field(key : String, placeholder~ : String = "***") -> RecordPatch {
  fn(rec) {
    rec.with_fields(rec.fields.map(fn(field) {
      if field.key == key {
        field.with_value(placeholder)
      } else {
        field
      }
    }))
  }
}

pub fn redact_fields(keys : Array[String], placeholder~ : String = "***") -> RecordPatch {
  fn(rec) {
    rec.with_fields(rec.fields.map(fn(field) {
      if keys.contains(field.key) {
        field.with_value(placeholder)
      } else {
        field
      }
    }))
  }
}

pub fn compose_patches(patches : Array[RecordPatch]) -> RecordPatch {
  fn(rec) {
    let mut current = rec
    for patch in patches {
      current = patch(current)
    }
    current
  }
}
