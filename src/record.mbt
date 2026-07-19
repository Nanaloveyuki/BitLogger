///|
pub type Field = @core.Field

///|
pub type TraceContext = @core.TraceContext

///|
pub fn field(key : String, value : String) -> Field {
  @core.field(key, value)
}

///|
pub fn fields(entries : Array[(String, String)]) -> Array[Field] {
  @core.fields(entries)
}

///|
pub fn trace_context(
  trace_id : String,
  span_id : String,
  trace_flags? : String = "01",
  trace_state? : String,
) -> TraceContext {
  match trace_state {
    Some(value) =>
      @core.TraceContext::new(
        trace_id,
        span_id,
        trace_flags~,
        trace_state=value,
      )
    None => @core.TraceContext::new(trace_id, span_id, trace_flags~)
  }
}

///|
pub type Record = @core.Record

///|
fn record(
  level : Level,
  message : String,
  timestamp_ms? : UInt64 = 0UL,
  target? : String = "",
  fields? : Array[Field] = [],
) -> Record {
  @core.Record::new(level, message, timestamp_ms~, target~, fields~)
}
