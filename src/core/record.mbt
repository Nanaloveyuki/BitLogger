///|
pub struct Field {
  key : String
  value : String
}

///|
pub fn field(key : String, value : String) -> Field {
  { key, value }
}

///|
pub fn fields(entries : Array[(String, String)]) -> Array[Field] {
  entries.map(fn(entry) { field(entry.0, entry.1) })
}

///|
pub struct Record {
  level : Level
  timestamp_ms : UInt64
  target : String
  message : String
  fields : Array[Field]
}

///|
pub fn Record::new(
  level : Level,
  message : String,
  timestamp_ms? : UInt64 = 0UL,
  target? : String = "",
  fields? : Array[Field] = [],
) -> Record {
  { level, timestamp_ms, target, message, fields }
}

///|
pub fn Field::with_value(self : Field, value : String) -> Field {
  field(self.key, value)
}

///|
pub fn Record::with_target(self : Record, target : String) -> Record {
  Record::new(
    self.level,
    self.message,
    timestamp_ms=self.timestamp_ms,
    target~,
    fields=self.fields,
  )
}

///|
pub fn Record::with_message(self : Record, message : String) -> Record {
  Record::new(
    self.level,
    message,
    timestamp_ms=self.timestamp_ms,
    target=self.target,
    fields=self.fields,
  )
}

///|
pub fn Record::with_fields(self : Record, fields : Array[Field]) -> Record {
  Record::new(
    self.level,
    self.message,
    timestamp_ms=self.timestamp_ms,
    target=self.target,
    fields~,
  )
}

///|
pub fn Record::copy(self : Record) -> Record {
  Record::new(
    self.level,
    self.message,
    timestamp_ms=self.timestamp_ms,
    target=self.target,
    fields=self.fields,
  )
}
