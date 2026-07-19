///|
let benchmark_record : @log.Record = @log.Record::new(
  @log.Level::Info,
  "benchmark record",
  target="bench",
  fields=[@log.field("component", "bitlogger")],
)

///|
test "bench callback logger emission" (it : @bench.T) {
  let writes : Ref[Int] = Ref(0)
  let logger = @log.Logger::new(@log.callback_sink(fn(_) { writes.val += 1 }))
  it.bench(fn() {
    logger.info("benchmark record", fields=[
      @log.field("component", "bitlogger"),
    ])
    it.keep(writes.val)
  })
}

///|
test "bench trace context field binding" (it : @bench.T) {
  let writes : Ref[Int] = Ref(0)
  let context = @log.trace_context("trace-bench", "span-bench")
  let logger = @log.Logger::new(@log.callback_sink(fn(_) { writes.val += 1 })).with_trace_context(
    context,
  )
  it.bench(fn() {
    logger.info("benchmark record", fields=[@log.field("event", "request")])
    it.keep(writes.val)
  })
}

///|
test "bench queued logger enqueue and flush" (it : @bench.T) {
  let writes : Ref[Int] = Ref(0)
  let logger = @log.Logger::new(@log.callback_sink(fn(_) { writes.val += 1 })).with_queue(
    max_pending=8,
  )
  it.bench(fn() {
    logger.info("benchmark record")
    it.keep(logger.sink.flush())
  })
}

///|
test "bench native file sink write" (it : @bench.T) {
  let sink = @log.file_sink(
    "logs/bitlogger-benchmark.log",
    append=false,
    auto_flush=false,
    formatter=fn(rec) { rec.message },
  )
  if sink.is_available() {
    it.bench(fn() {
      sink.write(benchmark_record)
      it.keep(sink.write_failures())
    })
    ignore(sink.close())
  }
}
