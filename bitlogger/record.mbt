pub struct Field {
  key : String
  value : String
}

pub fn field(key : String, value : String) -> Field {
  { key, value }
}

pub struct Record {
  level : Level
  timestamp_ms : UInt64
  target : String
  message : String
  fields : Array[Field]
}

pub fn Record::new(
  level : Level,
  message : String,
  timestamp_ms~ : UInt64 = 0UL,
  target~ : String = "",
  fields~ : Array[Field] = [],
) -> Record {
  { level, timestamp_ms, target, message, fields }
}

fn record(
  level : Level,
  message : String,
  timestamp_ms~ : UInt64 = 0UL,
  target~ : String = "",
  fields~ : Array[Field] = [],
) -> Record {
  Record::new(level, message, timestamp_ms=timestamp_ms, target=target, fields=fields)
}
