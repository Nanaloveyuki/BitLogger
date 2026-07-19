///|
test "trace context maps W3C fields in a stable order" {
  let context = trace_context(
    "4bf92f3577b34da6a3ce929d0e0e4736",
    "00f067aa0ba902b7",
    trace_state="vendor=value",
  )
  let fields = context.as_fields()
  inspect(fields.length(), content="4")
  inspect(fields[0].key, content="trace_id")
  inspect(fields[0].value, content="4bf92f3577b34da6a3ce929d0e0e4736")
  inspect(fields[1].key, content="span_id")
  inspect(fields[1].value, content="00f067aa0ba902b7")
  inspect(fields[2].key, content="trace_flags")
  inspect(fields[2].value, content="01")
  inspect(fields[3].key, content="trace_state")
  inspect(fields[3].value, content="vendor=value")
}

///|
test "sync facades bind trace context without mutating their base logger" {
  let captured : Ref[Array[Field]] = Ref([])
  let base = Logger::new(callback_sink(fn(rec) { captured.val = rec.fields }))
  let context = trace_context("trace-1", "span-1", trace_flags="00")
  let derived = base.with_trace_context(context)
  base.info("base")
  inspect(captured.val.length(), content="0")
  derived.info("derived", fields=[field("event", "request")])
  inspect(captured.val.length(), content="4")
  inspect(captured.val[0].key, content="trace_id")
  inspect(captured.val[2].value, content="00")
  inspect(captured.val[3].key, content="event")

  let library = LibraryLogger::new(
    callback_sink(fn(rec) { captured.val = rec.fields }),
  ).with_trace_context(context)
  library.info("library")
  inspect(captured.val.length(), content="3")
  inspect(captured.val[1].value, content="span-1")
}
