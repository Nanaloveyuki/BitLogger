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
  trace_flags? : String = "01",
  trace_state? : String,
) -> TraceContext {
  { trace_id, span_id, trace_flags, trace_state }
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
