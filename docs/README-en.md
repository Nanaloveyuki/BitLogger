# BitLogger

BitLogger is a structured logging library written in MoonBit.

## Overview

BitLogger currently provides:

- log levels: `Trace`, `Debug`, `Info`, `Warn`, `Error`
- structured key-value fields
- plain console output
- JSON console output
- child target composition via `child(...)`
- context fields via `with_context_fields(...)`
- optional timestamps via `with_timestamp()`
- sink fanout via `fanout_sink(...)`
- custom integration via `callback_sink(...)`
- in-memory buffering via `buffered_sink(...)`
- record filtering via `filter_sink(...)`
- reusable filter helpers such as `target_has_prefix(...)`, `message_contains(...)`, `level_at_least(...)`, and `field_equals(...)`
- record patching via `with_patch(...)` and `patch_sink(...)`
- patch helpers such as `prefix_message(...)`, `append_fields(...)`, and `redact_fields(...)`
- explicit queued delivery via `queued_sink(...)` and `with_queue(...)`
- bounded backlog with `QueueOverflowPolicy::DropNewest` and `QueueOverflowPolicy::DropOldest`
- configurable text formatting via `text_formatter(...)`, `format_text(...)`, and `text_console_sink(...)`
- formatter-based callback integration via `formatted_callback_sink(...)`
- native-only file output via `file_sink(...)`
- `native_files_supported()` for backend capability detection
- default global logger helpers

## Quick Start

```moonbit
let logger = Logger::new(console_sink(), min_level=Level::Info, target="demo")
  .with_timestamp()
  .with_context_fields([field("service", "bitlogger")])

logger.info("starting", fields=[field("port", "8080")])
```

Child target composition:

```moonbit
let worker = Logger::new(console_sink(), target="app").child("worker")
worker.info("job ready")
```

Custom callback sink:

```moonbit
let hook = Logger::new(
  callback_sink(fn(rec) {
    println("callback saw [\{rec.target}] \{rec.message}")
  }),
  target="hook",
)

hook.info("hello")
```

Basic buffered sink:

```moonbit
let sink = buffered_sink(console_sink(), flush_limit=2)
let logger = Logger::new(sink, target="buffered")

logger.info("one")
logger.info("two")
sink.flush()
```

Basic filter sink:

```moonbit
let sink = filter_sink(console_sink(), fn(rec) {
  rec.target == "kept"
})

let kept = Logger::new(sink, target="kept")
let dropped = Logger::new(sink, target="dropped")

kept.info("visible")
dropped.info("hidden")
```

Chained logger filter:

```moonbit
let logger = Logger::new(console_sink(), target="service")
  .with_filter(all_of([
    target_has_prefix("service"),
    message_contains("visible"),
  ]))

logger.info("hidden")
logger.child("api").info("visible")
```

Record patching:

```moonbit
let logger = Logger::new(console_sink(), target="auth")
  .with_patch(compose_patches([
    prefix_message("[safe] "),
    redact_fields(["token"]),
    append_fields([field("service", "bitlogger")]),
  ]))

logger.info("login", fields=[field("user", "alice"), field("token", "secret")])
```

Explicit queued sink:

```moonbit
let logger = Logger::new(console_sink(), target="queue")
  .with_queue(max_pending=2, overflow=QueueOverflowPolicy::DropOldest)

logger.info("one")
logger.info("two")
logger.info("three")
ignore(logger.sink.flush())
```

Custom text formatter:

```moonbit
let formatter = text_formatter(show_timestamp=false, separator=" | ")
let logger = Logger::new(text_console_sink(formatter), target="pretty")

logger.info("hello", fields=[field("mode", "pretty")])
```

Native file sink:

```moonbit
if native_files_supported() {
  let logger = Logger::new(file_sink("bitlogger.log"), target="file")
  logger.info("hello", fields=[field("kind", "file")])
  ignore(logger.sink.flush())
  ignore(logger.sink.close())
}
```

## Repository Layout

- `bitlogger/`: MoonBit library package, tests, and Mooncake package README
- `examples/basic/`: runnable example package

## Links

- [Mooncake package page](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [Chinese README](../README.md)
