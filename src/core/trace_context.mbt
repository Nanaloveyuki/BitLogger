///|
pub struct TraceContext {
  trace_id : String
  span_id : String
  trace_flags : String
  trace_state : String?
}

///|
pub fn TraceContext::new(
  trace_id : String,
  span_id : String,
  trace_flags~ : String = "01",
  trace_state? : String,
) -> TraceContext {
  let trace_id = match @otel.TraceId::from_hex(trace_id) {
    Some(id) => id.to_hex()
    None => trace_id
  }
  let span_id = match @otel.SpanId::from_hex(span_id) {
    Some(id) => id.to_hex()
    None => span_id
  }
  let trace_flags = match @otel.TraceFlags::from_hex(trace_flags) {
    Some(flags) => flags.to_hex()
    None => trace_flags
  }
  let trace_state = match trace_state {
    Some(value) =>
      Some(@otel.TraceState::from_header(value).to_header().unwrap_or(value))
    None => None
  }
  { trace_id, span_id, trace_flags, trace_state, }
}

///|
pub fn TraceContext::as_fields(self : TraceContext) -> Array[Field] {
  let fields = [
    field("trace_id", self.trace_id),
    field("span_id", self.span_id),
    field("trace_flags", self.trace_flags),
  ]
  match self.trace_state {
    Some(value) => fields.push(field("trace_state", value))
    None => ()
  }
  fields
}
