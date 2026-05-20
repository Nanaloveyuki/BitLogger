# BitLogger

BitLogger is a structured logging library written in MoonBit.

This README focuses on project positioning, core capabilities, and entry points. Detailed API coverage now lives in `docs/api/`.

## Overview

BitLogger is designed to provide composable, configurable, and cross-target logging infrastructure for MoonBit projects.

## Backend Compatibility

| Module / capability | native / llvm | js / wasm / wasm-gc |
| --- | --- | --- |
| `src` core package | Supported | Supported |
| `file_sink(...)` | Supported | Not available, `native_files_supported()` returns `false` |
| `src-async` | Native worker semantics | Compatibility implementation |
| `examples/async_basic` | Supported | Not shipped currently because `async fn main` entry support is still limited |

## Key Features

- Structured logging with levels, targets, and key-value fields.
- Composable sinks, filters, patches, fanout, routing, and queue wrappers.
- Config-driven runtime assembly through JSON parse/export helpers and `build_logger(...)` / `build_async_logger(...)`.
- Configurable text formatting with templates, style tags, and color control.
- Native file sink support with basic rotation, reopen helpers, and runtime observability.
- Separate async layer with bounded queueing, worker lifecycle control, runtime state, and cross-target compatibility.

## Quick Start

```moonbit
let logger = build_logger(
  with_queue(
    text_console(
      min_level=Level::Info,
      target="demo",
      text_formatter=TextFormatterConfig::new(show_timestamp=false, separator=" | "),
    ),
    max_pending=32,
    overflow=QueueOverflowPolicy::DropOldest,
  ),
)

logger.info("starting", fields=[field("port", "8080")])
ignore(logger.flush())
```

Start new synchronous code with `presets + build_logger(...)`: use `console(...)`, `json_console(...)`, `text_console(...)`, or `file(...)` to assemble `LoggerConfig`, optionally extend it with `with_queue(...)` or `with_file_rotation(...)`, then call `build_logger(...)`.

Switch to `Logger::new(...)` when you need direct runtime sink composition such as `fanout`, `split`, `callback`, or custom patch/filter graphs.

Async entry example:

```moonbit
let logger = async_logger(console_sink(), target="async.demo")
@async.with_task_group(group => {
  group.spawn_bg(() => logger.run())
  logger.info("started")
  logger.shutdown()
})
```

## Repository Layout

- `src/`: core logging package.
- `src-async/`: async logging layer built on `moonbitlang/async`.
- `docs/api/`: one-file-per-interface API documentation.
- `examples/basic/`: breadth example; starts with the recommended presets-based sync path and then sweeps broader capabilities.
- `examples/console_basic/`: minimal console and JSON console output.
- `examples/text_formatter/`: text formatter and template example.
- `examples/style_tags/`: style tag and colored formatter example.
- `examples/file_rotation/`: file sink and rotation example.
- `examples/config_build/`: config-driven `build_logger(...)` example.
- `examples/presets/`: presets-based construction example.
- `examples/async_basic/`: async logger example.

## Documentation Entry Points

- [Mooncake package page](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [Chinese README](../README.md)
- [src package README](../src/README.mbt.md)
- Recommended sync starting APIs: `text_console(...)`, `file(...)`, `with_queue(...)`, `build_logger(...)`
- Selected API docs in `docs/api/`:
- [logger-new.md](./api/logger-new.md)
- [async-logger.md](./api/async-logger.md)
- [build-logger.md](./api/build-logger.md)
- [build-async-logger.md](./api/build-async-logger.md)
- [build-application-logger.md](./api/build-application-logger.md)
- [build-library-logger.md](./api/build-library-logger.md)
- [build-application-async-logger.md](./api/build-application-async-logger.md)

## Notes

- `docs/README-en.md` no longer acts as an API catalog.
- Detailed API references, config fields, runtime control helpers, and lifecycle surfaces now live under `docs/api/`.
- For concrete runnable flows, prefer `examples/`.
