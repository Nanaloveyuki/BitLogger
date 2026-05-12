# BitLogger

BitLogger is a structured logging library written in MoonBit.

This README focuses on project positioning, core capabilities, and entry points. Detailed API coverage now lives in `docs/api/`.

## Overview

BitLogger is designed to provide composable, configurable, and cross-target logging infrastructure for MoonBit projects.

## Backend Compatibility

| Module / capability | native / llvm | js / wasm / wasm-gc |
| --- | --- | --- |
| `bitlogger` core package | Supported | Supported |
| `file_sink(...)` | Supported | Not available, `native_files_supported()` returns `false` |
| `bitlogger_async` | Native worker semantics | Compatibility implementation |
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
let logger = Logger::new(console_sink(), min_level=Level::Info, target="demo")
  .with_timestamp()
  .with_context_fields([field("service", "bitlogger")])

logger.info("starting", fields=[field("port", "8080")])
```

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

- `bitlogger/`: core logging package.
- `bitlogger_async/`: async logging layer built on `moonbitlang/async`.
- `docs/api/`: one-file-per-interface API documentation.
- `examples/basic/`: minimal synchronous example.
- `examples/async_basic/`: async logger example.

## Documentation Entry Points

- [Mooncake package page](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [Chinese README](../README.md)
- [bitlogger package README](../bitlogger/README.mbt.md)
- Selected API docs in `docs/api/`:
- [logger-new.md](./api/logger-new.md)
- [async-logger.md](./api/async-logger.md)
- [build-logger.md](./api/build-logger.md)
- [build-async-logger.md](./api/build-async-logger.md)

## Notes

- `docs/README-en.md` no longer acts as an API catalog.
- Detailed API references, config fields, runtime control helpers, and lifecycle surfaces now live under `docs/api/`.
- For concrete runnable flows, prefer `examples/`.

