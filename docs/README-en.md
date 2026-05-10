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
- lightweight style tags via `color_mode`, inline markup, `TextStyle`, `StyleTagRegistry`, custom tags, and builtin-tag overrides
- formatter-based callback integration via `formatted_callback_sink(...)`
- native-only file output via `file_sink(...)`, with basic size rotation, backup retention, explicit `reopen()` / `reopen_with_current_policy()` / `reopen_append()` / `reopen_truncate()`, and failure counters
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
  color_mode=ColorMode::Always,
)
let logger = Logger::new(text_console_sink(formatter), target="pretty")

logger.info("hello", fields=[field("mode", "pretty")])
```

Inline style tags:

```moonbit
let formatter = text_formatter(
  show_timestamp=false,
  color_mode=ColorMode::Always,
).with_style_tags(
  default_style_tag_registry()
    .set_tag("accent", fg=Some("#4cc9f0"), bold=true)
    .define_alias("danger", "red"),
)

let logger = Logger::new(text_console_sink(formatter), target="styled")

logger.info("<accent>styled</> output and <danger>alert</>")
```

JSON config loading:

```moonbit
let config = parse_logger_config_text(
  "{\"min_level\":\"debug\",\"target\":\"config.demo\",\"timestamp\":true,\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"field_separator\":\",\",\"template\":\"[{level}] {target} {message} :: {fields}\",\"color_mode\":\"always\"}},\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"}}",
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

File runtime state dump:

```moonbit
let logger = build_logger(
  LoggerConfig::new(
    sink=SinkConfig::new(kind=SinkKind::File, path="bitlogger-runtime.log"),
    queue=Some(QueueConfig::new(16)),
  ),
)

logger.info("queued hello")

match logger.file_runtime_state() {
  Some(snapshot) => println(stringify_runtime_file_state(snapshot, pretty=true))
  None => ()
}
```

## Repository Layout

- `bitlogger/`: MoonBit library package, tests, and Mooncake package README
- `examples/basic/`: runnable example package
- `examples/async_basic/`: runnable async logger example built on `moonbitlang/async`

## Links

- [Mooncake package page](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [Chinese README](../README.md)

## Config Notes

- BitLogger now includes a JSON config layer via `parse_logger_config_text(...)`, `stringify_logger_config(...)`, and `build_logger(...)`.
- `QueueConfig`, `TextFormatterConfig`, and `SinkConfig` can also be exported independently through `queue_config_to_json(...)` / `stringify_queue_config(...)`, `text_formatter_config_to_json(...)` / `stringify_text_formatter_config(...)`, and `sink_config_to_json(...)` / `stringify_sink_config(...)`.
- Supported keys include `min_level`, `target`, `timestamp`, `sink.kind`, `sink.path`, `sink.append`, `sink.auto_flush`, `sink.rotation`, `sink.text_formatter`, and `queue`.
- `TextFormatter` and `TextFormatterConfig` now include `color_mode = Never | Auto | Always` for ANSI text coloring control.
- `message` also supports lightweight inline style tags such as `<red>...</>`, `<b>...</>`, `<#ff0000>...</>`, and `<bg:#202020>...</>`.
- Runtime style-tag APIs now include `TextStyle`, `StyleTagRegistry`, `style_tag_registry()`, `default_style_tag_registry()`, `set_tag(...)`, and `define_alias(...)`.
- Style-tag lookup priority is formatter-local `style_tags` > global style tag registry > builtin tags.
- Custom style tags are runtime-only for now and are not yet part of the JSON config schema.
- `sink.rotation` currently supports `max_bytes` and `max_backups` for basic size-based rotation and backup retention.
- `file_sink(...)` also exposes `reopen()`, `reopen_with_current_policy()`, `reopen_append()`, `reopen_truncate()`, `open_failures()`, `write_failures()`, `flush_failures()`, and `rotation_failures()` for basic observability.
- `file_sink(...)` also exposes `append_mode()`. Passing `append=...` to `reopen(...)` updates the current append policy used by later reopen calls, `reopen_with_current_policy()` makes that stored-policy reopen path explicit, and `reopen_append()` / `reopen_truncate()` cover the two common policy switches directly.
- `file_sink(...)` also supports `set_append_mode(...)` for explicitly changing the append policy that later reopen calls will use.
- `file_sink(...)` also exposes `path()` and `auto_flush_enabled()` for reading basic file-sink policy state.
- `file_sink(...)` also exposes `rotation_enabled()` and `rotation_config()` for reading whether rotation is active and which parameters are currently in effect.
- `file_sink(...)` also exposes `state()` for reading a single snapshot that includes path, availability, append policy, auto-flush flag, rotation config, and all current failure counters.
- `file_sink(...)` also exposes `policy()` and `default_policy()` for reading the current runtime policy and the sink's original default policy separately.
- `file_sink(...)` also exposes `policy_matches_default()` for explicitly checking whether the current runtime policy has drifted from the original defaults.
- `file_sink(...)` also exposes `set_policy(...)` for applying append, auto-flush, and rotation as a single bundled runtime policy update.
- `file_sink(...)` also exposes `reset_failure_counters()` so open/write/flush/rotation failure counters can be cleared after diagnostics or recovery handling.
- `file_sink(...)` also exposes `reset_policy()` so append, auto-flush, and rotation settings can be restored to the sink's original defaults.
- `file_sink(...)` also supports `set_auto_flush(...)`, `set_rotation(...)`, and `clear_rotation()` for runtime policy updates.
- `ConfiguredLogger` built through `build_logger(...)` also exposes `file_reopen()`, `file_reopen_with_current_policy()`, `file_reopen_append()`, `file_reopen_truncate()`, `file_flush()`, `file_close()`, `file_append_mode()`, `file_path()`, `file_auto_flush()`, `file_rotation_enabled()`, `file_rotation_config()`, `file_state()`, plus `file_set_append_mode(...)`, `file_set_auto_flush(...)`, `file_set_rotation(...)`, `file_clear_rotation()`, and the corresponding file failure counters, so config-driven file logging keeps a usable control surface.
- `ConfiguredLogger` also exposes `file_runtime_state()` so queued file loggers can report both the underlying file snapshot and the outer queue backlog/drop state in one read.
- `ConfiguredLogger` also exposes `file_policy()` and `file_default_policy()` for reading current runtime file policy and initial config policy separately.
- `ConfiguredLogger` also exposes `file_policy_matches_default()` for explicitly checking whether the current runtime file policy differs from its default config.
- `ConfiguredLogger` also exposes `file_set_policy(...)` for applying a bundled runtime file policy through the config-built control surface.
- `ConfiguredLogger` also exposes `file_reset_failure_counters()` for clearing file failure counters through the config-built control surface.
- `ConfiguredLogger` also exposes `file_reset_policy()` for restoring runtime file policy back to the initial config values.
- `file_sink_policy_to_json(...)` and `stringify_file_sink_policy(...)` can export standalone file-policy snapshots directly as JSON for policy diffing, diagnostics, or reporting.
- `file_sink_state_to_json(...)`, `stringify_file_sink_state(...)`, `runtime_file_state_to_json(...)`, and `stringify_runtime_file_state(...)` can export file and queued-file snapshots directly as JSON for diagnostics or reporting.
- `sink.text_formatter.template` currently supports fixed tokens: `{timestamp}`, `{timestamp_ms}`, `{level}`, `{target}`, `{message}`, and `{fields}`.
- `sink.text_formatter.color_mode` currently supports `never`, `auto`, and `always`.
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
