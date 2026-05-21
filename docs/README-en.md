# BitLogger

BitLogger is a structured logging library written in MoonBit.

This README focuses on project positioning, core capabilities, and entry points. Detailed API coverage now lives in `docs/api/`.

## Overview

BitLogger is designed to provide composable, configurable, and cross-target logging infrastructure for MoonBit projects.

## Backend Compatibility

Currently verified targets: `native`, `js`, `wasm`, and `wasm-gc`.

`llvm` should still be treated as experimental here: verification did not complete in the current environment, and local reproduction depends on nightly / llvm toolchain conditions, so it is not presented as a stable promise at the same level as `native`.

| Module / capability | Verified targets | `llvm` |
| --- | --- | --- |
| `src` core package | Verified on `native`, `js`, `wasm`, and `wasm-gc` | Experimental; not fully verified in the current environment |
| `file(...)` / `file_sink(...)` | Verified only on `native`; unavailable on non-native targets and `native_files_supported()` returns `false` | Not presented as a verified capability |
| `src-async` | Local verification passed on `native` and `wasm`; other non-native targets still follow the compatibility-implementation wording | Experimental; not fully verified in the current environment |
| portable examples (`console_basic` / `text_formatter` / `style_tags` / `config_build` / `presets`) | Verified on `native` and `wasm-gc` | Not yet verified here |
| `examples/file_rotation` | Verified on `native`; non-native targets print a clear skip message because file sinks are unavailable | Not yet verified here |
| `examples/async_basic` | Verified on `native`; non-native example shipping is still limited by the current `async fn main` entry path | Not yet verified here |

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

For cross-target code, prefer the console, json console, text console, and config-parser paths first. File sinks and file presets remain native-sensitive and should be gated with `native_files_supported()`.

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
- `examples/console_basic/`: portable minimal console and JSON console output.
- `examples/text_formatter/`: portable text formatter and template example.
- `examples/style_tags/`: portable style tag and colored formatter example.
- `examples/file_rotation/`: target-sensitive file sink and rotation example with an explicit non-native skip path.
- `examples/config_build/`: portable config-driven `build_logger(...)` example.
- `examples/presets/`: portable-first presets example; adds file preset usage only when native file support is available.
- `examples/async_basic/`: native-only async logger example; the limitation is the `async fn main` entry path, not the absence of `src-async` compatibility APIs.

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
