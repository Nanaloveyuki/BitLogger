test "default logger can be reconfigured" {
  set_default_min_level(Level::Debug)
  set_default_target("global")
  let logger = default_logger()
  inspect(logger.min_level.label(), content="DEBUG")
  inspect(logger.target, content="global")
}

test "logger can enable timestamps" {
  let logger = Logger::new(console_sink(), min_level=Level::Info, target="time")
    .with_timestamp()
  inspect(logger.timestamp, content="true")
}

test "text formatter can customize visible parts" {
  let rec = record(
    Level::Info,
    "hello",
    timestamp_ms=123UL,
    target="svc.api",
    fields=[field("user", "alice"), field("request_id", "42")],
  )
  let compact = text_formatter(show_timestamp=false, show_target=false, field_separator=",")
  inspect(format_text(rec, formatter=compact), content="[INFO] hello user=alice,request_id=42")
}

test "text formatter can emit message only" {
  let rec = record(
    Level::Warn,
    "just message",
    timestamp_ms=999UL,
    target="svc",
    fields=[field("ignored", "yes")],
  )
  let message_only = text_formatter(
    show_timestamp=false,
    show_level=false,
    show_target=false,
    show_fields=false,
  )
  inspect(format_text(rec, formatter=message_only), content="just message")
}

test "text formatter supports template rendering" {
  let rec = record(
    Level::Info,
    "template hello",
    timestamp_ms=123UL,
    target="svc.api",
    fields=[field("user", "alice"), field("request_id", "42")],
  )
  let formatter = text_formatter(
    separator=" | ",
    field_separator=",",
    template="[{level}] {target} {message} :: {fields} @{timestamp}",
  )
  inspect(
    format_text(rec, formatter=formatter),
    content="[INFO] svc.api template hello :: user=alice,request_id=42 @123",
  )
}

test "text formatter template respects disabled fields" {
  let rec = record(Level::Warn, "just message", target="svc")
  let formatter = text_formatter(
    show_target=false,
    show_fields=false,
    template="[{level}] {target}{message}{fields}",
  )
  inspect(format_text(rec, formatter=formatter), content="[WARN] just message")
}

test "formatted callback sink receives rendered text" {
  let rendered : Ref[String] = Ref::new("")
  let sink = text_callback_sink(
    text_formatter(show_timestamp=false, separator=" | "),
    fn(text) {
      rendered.val = text
    },
  )
  let logger = Logger::new(sink, min_level=Level::Info, target="svc")
  logger.info("hello", fields=[field("user", "alice")])
  inspect(rendered.val, content="[INFO] | [svc] | hello | user=alice")
}

test "native file support flag is queryable" {
  inspect(native_files_supported() == true || native_files_supported() == false, content="true")
}

test "file sink availability reflects backend support" {
  let sink = file_sink("bitlogger-test.log")
  inspect(sink.is_available() == native_files_supported(), content="true")
  if sink.is_available() {
    inspect(sink.flush(), content="true")
    inspect(sink.close(), content="true")
  } else {
    inspect(sink.flush(), content="false")
    inspect(sink.close(), content="false")
  }
}

test "json formatter keeps structured shape" {
  let rec = record(
    Level::Error,
    "failed",
    timestamp_ms=55UL,
    target="svc",
    fields=[field("code", "500")],
  )
  inspect(
    format_json(rec),
    content="{\"level\":\"ERROR\",\"message\":\"failed\",\"fields\":{\"code\":\"500\"},\"timestamp_ms\":\"55\",\"target\":\"svc\"}",
  )
}

test "callback sink receives record" {
  let captured_target : Ref[String] = Ref::new("")
  let captured_message : Ref[String] = Ref::new("")
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

test "callback sink sees child target and context logger shape" {
  let captured_target : Ref[String] = Ref::new("")
  let captured_message : Ref[String] = Ref::new("")
  let captured_field_count : Ref[Int] = Ref::new(0)
  let captured_timestamp : Ref[UInt64] = Ref::new(0UL)
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_field_count.val = rec.fields.length()
      captured_timestamp.val = rec.timestamp_ms
    }),
    min_level=Level::Info,
    target="app",
  )
    .child("worker")
    .with_context_fields([field("service", "bitlogger")])
    .with_timestamp()
  logger.info("ready", fields=[field("mode", "test")])
  inspect(captured_target.val, content="app.worker")
  inspect(captured_message.val, content="ready")
  inspect(captured_field_count.val, content="2")
  inspect(captured_timestamp.val > 0UL, content="true")
}

test "buffered sink flushes manually" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let sink = buffered_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
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

test "buffered sink flushes automatically at limit" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let sink = buffered_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
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

test "filter sink only forwards matching records" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let sink = filter_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    fn(rec) {
      rec.target == "kept"
    },
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

test "logger with_filter composes naturally" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Info,
    target="app",
  )
    .with_filter(fn(rec) {
      rec.target == "app.worker"
    })
  logger.info("drop at app")
  logger.child("worker").info("keep at worker")
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="keep at worker")
}

test "filter helpers support target level and message composition" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Trace,
    target="service",
  ).with_filter(all_of([
    target_has_prefix("service"),
    level_at_least(Level::Info),
    message_contains("visible"),
  ]))
  logger.debug("visible debug")
  logger.info("hidden info")
  logger.child("api").info("visible info")
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="visible info")
}

test "field helpers can match and negate records" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Info,
    target="fields",
  ).with_filter(all_of([
    has_field("request_id"),
    field_equals("kind", "audit"),
    not_(target_is("fields.drop")),
  ]))
  logger.info("missing field")
  logger.info("wrong kind", fields=[field("request_id", "1"), field("kind", "trace")])
  logger.child("drop").info("blocked target", fields=[field("request_id", "2"), field("kind", "audit")])
  logger.info("kept", fields=[field("request_id", "3"), field("kind", "audit")])
  inspect(flushed_messages.val.length(), content="1")
  inspect(flushed_messages.val[0], content="kept")
}

test "any_of helper accepts multiple predicates" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
    min_level=Level::Info,
    target="multi",
  ).with_filter(any_of([
    target_is("multi.keep"),
    field_equals("force", "true"),
  ]))
  logger.info("drop")
  logger.child("keep").info("keep by target")
  logger.info("keep by field", fields=[field("force", "true")])
  inspect(flushed_messages.val.length(), content="2")
  inspect(flushed_messages.val[0], content="keep by target")
  inspect(flushed_messages.val[1], content="keep by field")
}

test "patch sink can rewrite message target and fields" {
  let captured_target : Ref[String] = Ref::new("")
  let captured_message : Ref[String] = Ref::new("")
  let captured_fields : Ref[Array[Field]] = Ref::new([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_target.val = rec.target
      captured_message.val = rec.message
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="auth",
  ).with_patch(compose_patches([
    set_target("audit.auth"),
    prefix_message("[safe] "),
    redact_field("token"),
    append_fields([field("service", "bitlogger")]),
  ]))
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

test "patch helpers can redact multiple fields" {
  let captured_fields : Ref[Array[Field]] = Ref::new([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      captured_fields.val = rec.fields
    }),
    min_level=Level::Info,
    target="audit",
  ).with_patch(redact_fields(["token", "password"], placeholder="[redacted]"))
  logger.info(
    "credentials",
    fields=[field("token", "abc"), field("password", "123"), field("user", "alice")],
  )
  inspect(captured_fields.val.length(), content="3")
  inspect(captured_fields.val[0].value, content="[redacted]")
  inspect(captured_fields.val[1].value, content="[redacted]")
  inspect(captured_fields.val[2].value, content="alice")
}

test "queued sink drains in order" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let sink = queued_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
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

test "queued sink can drop newest when full" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let sink = queued_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
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

test "queued sink can drop oldest when full" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let sink = queued_sink(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
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

test "logger with_queue preserves chaining ergonomics" {
  let flushed_messages : Ref[Array[String]] = Ref::new([])
  let logger = Logger::new(
    callback_sink(fn(rec) {
      flushed_messages.val.push(rec.message)
    }),
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
