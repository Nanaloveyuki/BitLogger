pub type Field = @core.Field

pub fn field(key : String, value : String) -> Field {
  @core.field(key, value)
}

pub fn fields(entries : Array[(String, String)]) -> Array[Field] {
  @core.fields(entries)
}

pub type Record = @core.Record

fn record(
  level : Level,
  message : String,
  timestamp_ms~ : UInt64 = 0UL,
  target~ : String = "",
  fields~ : Array[Field] = [],
) -> Record {
  @core.Record::new(level, message, timestamp_ms=timestamp_ms, target=target, fields=fields)
}
