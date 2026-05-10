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
- sink routing via `split_sink(...)` and `split_by_level(...)`
- custom integration via `callback_sink(...)`
- in-memory buffering via `buffered_sink(...)`
- record filtering via `filter_sink(...)`
- reusable filter helpers such as `target_has_prefix(...)`, `message_contains(...)`, `level_at_least(...)`, and `field_equals(...)`
- record patching via `with_patch(...)` and `patch_sink(...)`
- patch helpers such as `prefix_message(...)`, `append_fields(...)`, and `redact_fields(...)`
- context binding via `bind(...)` and `fields(...)`
- explicit queued delivery via `queued_sink(...)` and `with_queue(...)`
- bounded backlog with `QueueOverflowPolicy::DropNewest` and `QueueOverflowPolicy::DropOldest`
- configurable text formatting via `text_formatter(...)`, `format_text(...)`, `text_console_sink(...)`, and template-driven `template` output
- formatter-based callback integration via `formatted_callback_sink(...)`
- native-only file output via `file_sink(...)`, with basic size rotation, backup retention, explicit `reopen()` / `reopen_with_current_policy()`, and failure counters
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

Context binding:

```moonbit
let logger = Logger::new(console_sink(), target="audit")
  .bind(fields([("service", "bitlogger"), ("scope", "login")]))

logger.info("accepted", fields=[field("user", "alice")])
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

Level-based split sink:

```moonbit
let logger = Logger::new(
  split_by_level(
    callback_sink(fn(rec) {
      println("high priority: \{rec.level.label()} \{rec.message}")
    }),
    console_sink(),
    min_level=Level::Warn,
  ),
  min_level=Level::Trace,
  target="split",
)

logger.info("normal output")
logger.warn("warning output")
```

Custom text formatter:

```moonbit
let formatter = text_formatter(
  show_timestamp=false,
  field_separator=",",
  template="[{level}] {target} {message} :: {fields}",
)
let logger = Logger::new(text_console_sink(formatter), target="pretty")

logger.info("hello", fields=[field("mode", "pretty")])
```

JSON config loading:

```moonbit
let config = parse_logger_config_text(
  "{\"min_level\":\"debug\",\"target\":\"config.demo\",\"timestamp\":true,\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"field_separator\":\",\",\"template\":\"[{level}] {target} {message} :: {fields}\"}},\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"}}",
)

let logger = build_logger(config)

logger.info("configured from json")
ignore(logger.flush())
```

Native file sink:

```moonbit
if native_files_supported() {
  let logger = Logger::new(
    file_sink("bitlogger.log", rotation=Some(file_rotation(128, max_backups=2))),
    target="file",
  )
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

## Config Notes

- BitLogger now includes a JSON config layer via `parse_logger_config_text(...)`, `stringify_logger_config(...)`, and `build_logger(...)`.
- Supported keys include `min_level`, `target`, `timestamp`, `sink.kind`, `sink.path`, `sink.append`, `sink.auto_flush`, `sink.rotation`, `sink.text_formatter`, and `queue`.
- `sink.rotation` currently supports `max_bytes` and `max_backups` for basic size-based rotation and backup retention.
- `file_sink(...)` also exposes `reopen()`, `reopen_with_current_policy()`, `open_failures()`, `write_failures()`, `flush_failures()`, and `rotation_failures()` for basic observability.
- `file_sink(...)` also exposes `append_mode()`. Passing `append=...` to `reopen(...)` updates the current append policy used by later reopen calls, while `reopen_with_current_policy()` makes that stored-policy reopen path explicit.
- `file_sink(...)` also supports `set_append_mode(...)` for explicitly changing the append policy that later reopen calls will use.
- `file_sink(...)` also exposes `path()` and `auto_flush_enabled()` for reading basic file-sink policy state.
- `file_sink(...)` also exposes `rotation_enabled()` and `rotation_config()` for reading whether rotation is active and which parameters are currently in effect.
- `file_sink(...)` also supports `set_auto_flush(...)`, `set_rotation(...)`, and `clear_rotation()` for runtime policy updates.
- `ConfiguredLogger` built through `build_logger(...)` also exposes `file_reopen()`, `file_reopen_with_current_policy()`, `file_flush()`, `file_close()`, `file_append_mode()`, `file_path()`, `file_auto_flush()`, `file_rotation_enabled()`, `file_rotation_config()`, plus `file_set_append_mode(...)`, `file_set_auto_flush(...)`, `file_set_rotation(...)`, `file_clear_rotation()`, and the corresponding file failure counters, so config-driven file logging keeps a usable control surface.
- `sink.text_formatter.template` currently supports fixed tokens: `{timestamp}`, `{timestamp_ms}`, `{level}`, `{target}`, `{message}`, and `{fields}`.
- Config-driven sink assembly currently supports `console`, `json_console`, `text_console`, and `file`.
- `queue` remains a synchronous bounded wrapper around the final sink, not an async runtime.

## Async Layer

- A separate `bitlogger_async/` package is now included.
- It uses `moonbitlang/async` and provides `AsyncLogger`, `async_logger(...)`, a background `run()` worker, and bounded async queue delivery.
- The current async API already supports `with_context_fields(...)`, `with_filter(...)`, `with_patch(...)`, `with_target(...)`, and `child(...)`.
- `shutdown()` is now the recommended way to stop the async worker. By default it waits for the queue to drain, closes the queue, and then waits for the worker to exit.
- Basic lifecycle observability is also available through `is_closed()`, `is_running()`, `has_failed()`, and `last_error()`.
- The async worker now supports batched queue draining via `max_batch` and basic flush policies through `flush=Never|Batch|Shutdown`.
- The recommended startup pattern is shown in [examples/async_basic/main.mbt](/E:/repo/MooLiteyukiBot/examples/async_basic/main.mbt:1).
- This layer currently targets `native/llvm` only and remains isolated from the synchronous logger core.

### Async Config

- `parse_async_logger_config_text(...)`, `stringify_async_logger_config(...)`, `parse_async_logger_build_config_text(...)`, and `build_async_logger(...)` are now available.
- The JSON root is split into `logger` and `async_config`.
- `logger` fully reuses the synchronous `LoggerConfig` schema, while `async_config` currently supports `max_pending`, `overflow`, `max_batch`, and `flush`.
- The recommended config-driven startup flow is shown in [examples/async_basic/main.mbt](/E:/repo/MooLiteyukiBot/examples/async_basic/main.mbt:1).
