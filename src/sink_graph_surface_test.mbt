///|
test "callback sink receives record" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
    }),
    min_level=Level::Info,
    target="callback",
  )
  logger.info("hello")
  inspect(captured_target.val, content="callback")
  inspect(captured_message.val, content="hello")
}

///|
test "history sink retains the newest copied records" {
  let sink = history_sink(capacity=2)
  let logger = Logger::new(sink, min_level=Level::Info, target="history")
  logger.info("one", fields=[field("position", "first")])
  logger.info("two")
  logger.info("three")

  inspect(sink.capacity(), content="2")
  inspect(sink.count(), content="2")
  inspect(sink.dropped_count(), content="1")
  let snapshot = sink.snapshot()
  inspect(snapshot.length(), content="2")
  inspect(snapshot[0].message, content="two")
  inspect(snapshot[1].message, content="three")
  snapshot[0].fields.push(field("mutated", "outside"))
  inspect(sink.snapshot()[0].fields.length(), content="0")
}

///|
test "history sink normalizes capacity and clear resets its session" {
  let sink = history_sink(capacity=0)
  let logger = Logger::new(sink, min_level=Level::Info, target="history")
  logger.info("one")
  logger.info("two")

  inspect(sink.capacity(), content="1")
  inspect(sink.count(), content="1")
  inspect(sink.dropped_count(), content="1")
  sink.clear()
  inspect(sink.count(), content="0")
  inspect(sink.dropped_count(), content="0")
}

///|
test "split sink routes records by predicate" {
  let left_messages : Ref[Array[String]] = Ref([])
  let right_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    split_sink(
      callback_sink(fn(rec) { left_messages.val.push(rec.message) }),
      callback_sink(fn(rec) { right_messages.val.push(rec.message) }),
      fn(rec) { rec.target == "audit" },
    ),
    min_level=Level::Info,
    target="main",
  )
  logger.info("drop to right")
  logger.log(Level::Info, "keep on left", target="audit")
  inspect(left_messages.val.length(), content="1")
  inspect(left_messages.val[0], content="keep on left")
  inspect(right_messages.val.length(), content="1")
  inspect(right_messages.val[0], content="drop to right")
}

///|
test "split_by_level routes warn and error separately" {
  let high_messages : Ref[Array[String]] = Ref([])
  let low_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    split_by_level(
      callback_sink(fn(rec) {
        high_messages.val.push(rec.level.label() + ":" + rec.message)
      }),
      callback_sink(fn(rec) {
        low_messages.val.push(rec.level.label() + ":" + rec.message)
      }),
      min_level=Level::Warn,
    ),
    min_level=Level::Trace,
    target="split",
  )
  logger.info("info")
  logger.warn("warn")
  logger.error("error")
  inspect(high_messages.val.length(), content="2")
  inspect(high_messages.val[0], content="WARN:warn")
  inspect(high_messages.val[1], content="ERROR:error")
  inspect(low_messages.val.length(), content="1")
  inspect(low_messages.val[0], content="INFO:info")
}

///|
test "buffered sink flushes manually" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = buffered_sink(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    flush_limit=10,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="buffered")
  logger.info("one")
  logger.info("two")
  inspect(sink.pending_count(), content="2")
  inspect(flushed_messages.val.length(), content="0")
  sink.flush()
  inspect(sink.pending_count(), content="0")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
}

///|
test "buffered sink flushes automatically at limit" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = buffered_sink(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    flush_limit=2,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="buffered")
  logger.info("one")
  inspect(sink.pending_count(), content="1")
  logger.info("two")
  inspect(sink.pending_count(), content="0")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
}

///|
test "filter sink only forwards matching records" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = filter_sink(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    fn(rec) { rec.target == "kept" },
  )
  let kept = Logger::new(sink, min_level=Level::Info, target="kept")
  let dropped = Logger::new(sink, min_level=Level::Info, target="dropped")
  kept.info("one")
  dropped.info("two")
  kept.info("three")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="three")
}

///|
test "logger with_filter composes naturally" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    min_level=Level::Info,
    target="app",
  ).with_filter(fn(rec) { rec.target == "app.worker" })
  logger.info("drop at app")
  logger.child("worker").info("keep at worker")
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="keep at worker")
}

///|
test "filter helpers support target level and message composition" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    min_level=Level::Trace,
    target="service",
  ).with_filter(
    all_of([
      target_has_prefix("service"),
      level_at_least(Level::Info),
      message_contains("visible"),
    ]),
  )
  logger.debug("visible debug")
  logger.info("hidden info")
  logger.child("api").info("visible info")
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="visible info")
}

///|
test "field helpers can match and negate records" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    min_level=Level::Info,
    target="fields",
  ).with_filter(
    all_of([
      has_field("request_id"),
      field_equals("kind", "audit"),
      not_(target_is("fields.drop")),
    ]),
  )
  logger.info("missing field")
  logger.info("wrong kind", fields=[
    field("request_id", "1"),
    field("kind", "trace"),
  ])
  logger
  .child("drop")
  .info("blocked target", fields=[
    field("request_id", "2"),
    field("kind", "audit"),
  ])
  logger.info("kept", fields=[field("request_id", "3"), field("kind", "audit")])
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="kept")
}

///|
test "any_of helper accepts multiple predicates" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    min_level=Level::Info,
    target="multi",
  ).with_filter(
    any_of([target_is("multi.keep"), field_equals("force", "true")]),
  )
  logger.info("drop")
  logger.child("keep").info("keep by target")
  logger.info("keep by field", fields=[field("force", "true")])
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="keep by target")
  inspect(flushed_messages.val[1], content="keep by field")
}

///|
test "patch sink can rewrite message target and fields" {
  let captured_target : Ref[String] = Ref("")
  let captured_message : Ref[String] = Ref("")
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="auth",
  ).with_patch(
    compose_patches([
      set_target("audit.auth"),
      prefix_message("[safe] "),
      redact_field("token"),
      append_fields([field("service", "bitlogger")]),
    ]),
  )
  logger.info("login", fields=[field("token", "secret"), field("user", "alice")])
  inspect(captured_target.val, content="audit.auth")
  inspect(captured_message.val, content="[safe] login")
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].key, content="token")
  inspect(captured_fields.val[0].value, content="***")
  inspect(captured_fields.val[1].key, content="user")
  inspect(captured_fields.val[1].value, content="alice")
  inspect(captured_fields.val[2].key, content="service")
  inspect(captured_fields.val[2].value, content="bitlogger")
}

///|
test "patch helpers can redact multiple fields" {
  let captured_fields : Ref[Array[Field]] = Ref([])
  let logger = Logger::new(
    callback_sink(fn(rec) { captured_fields.val = rec.fields }),
    min_level=Level::Info,
    target="audit",
  ).with_patch(redact_fields(["token", "password"], placeholder="[redacted]"))
  logger.info("credentials", fields=[
    field("token", "abc"),
    field("password", "123"),
    field("user", "alice"),
  ])
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].value, content="[redacted]")
  inspect(captured_fields.val[1].value, content="[redacted]")
  inspect(captured_fields.val[2].value, content="alice")
}

///|
test "queued sink drains in order" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = queued_sink(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="3")
  inspect(sink.dropped_count(), content="0")
  inspect(sink.drain(max_items=2), content="2")
  inspect(sink.pending_count(), content="1")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
  inspect(sink.flush(), content="1")
  inspect(sink.pending_count(), content="0")
  inspect(flushed_messages.val[2], content="three")
}

///|
test "queued sink can drop newest when full" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = queued_sink(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    max_pending=2,
    overflow=QueueOverflowPolicy::DropNewest,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  inspect(sink.flush(), content="2")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="one")
  inspect(flushed_messages.val[1], content="two")
}

///|
test "queued sink can drop oldest when full" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let sink = queued_sink(
    callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
    max_pending=2,
    overflow=QueueOverflowPolicy::DropOldest,
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="queue")
  logger.info("one")
  logger.info("two")
  logger.info("three")
  inspect(sink.pending_count(), content="2")
  inspect(sink.dropped_count(), content="1")
  inspect(sink.flush(), content="2")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="two")
  inspect(flushed_messages.val[1], content="three")
}

///|
test "logger with_queue preserves chaining ergonomics" {
  let flushed_messages : Ref[Array[String]] = Ref([])
  let logger = Logger::new(
      callback_sink(fn(rec) { flushed_messages.val.push(rec.message) }),
      min_level=Level::Info,
      target="service",
    )
    .with_patch(prefix_message("[queued] "))
    .with_queue(max_pending=2, overflow=QueueOverflowPolicy::DropOldest)
  logger.info("one")
  logger.child("api").info("two")
  logger.info("three")
  inspect(logger.sink.pending_count(), content="2")
  inspect(logger.sink.dropped_count(), content="1")
  inspect(logger.sink.flush(), content="2")
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="[queued] two")
  inspect(flushed_messages.val[1], content="[queued] three")
}
