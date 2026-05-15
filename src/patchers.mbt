pub type RecordPatch = (Record) -> Record

pub fn identity_patch() -> RecordPatch {
  fn(rec) { rec }
}

pub fn set_target(target : String) -> RecordPatch {
  fn(rec) {
    { ..rec, target }
  }
}

pub fn prefix_message(prefix : String) -> RecordPatch {
  fn(rec) {
    { ..rec, message: "\{prefix}\{rec.message}" }
  }
}

pub fn append_fields(extra_fields : Array[Field]) -> RecordPatch {
  fn(rec) {
    if extra_fields.length() == 0 {
      rec
    } else if rec.fields.length() == 0 {
      { ..rec, fields: extra_fields }
    } else {
      { ..rec, fields: rec.fields + extra_fields }
    }
  }
}

pub fn redact_field(key : String, placeholder~ : String = "***") -> RecordPatch {
  fn(rec) {
    {
      ..rec,
      fields: rec.fields.map(fn(field) {
        if field.key == key {
          { ..field, value: placeholder }
        } else {
          field
        }
      }),
    }
  }
}

pub fn redact_fields(keys : Array[String], placeholder~ : String = "***") -> RecordPatch {
  fn(rec) {
    {
      ..rec,
      fields: rec.fields.map(fn(field) {
        if keys.contains(field.key) {
          { ..field, value: placeholder }
        } else {
          field
        }
      }),
    }
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
