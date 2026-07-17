# BitLogger

BitLogger is a structured logging library for MoonBit projects.

- [Mooncake package page](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [Chinese README](https://github.com/Nanaloveyuki/BitLogger/blob/main/README.md)

## Overview

BitLogger gives you consistent levels, targets, structured fields, configurable text output, native file logging, and an async logging layer.

## Start With A Working Flow

The documentation is organized around complete usage flows. Start with an executable logger, then move into file output, configuration, async lifecycle, and extensions. The API reference remains the precise symbol-level reference.

### 1. Install

```bash
moon new log-demo
cd log-demo
moon add Nanaloveyuki/BitLogger@0.7.0
```

### 2. Import And Log

Add the package import to your application's `moon.pkg`:

```moonbit
import {
  "Nanaloveyuki/BitLogger/src" @log,
}
```

```moonbit
fn main {
  let logger = @log.build_logger(
    @log.console(min_level=@log.Level::Info, target="app"),
  )
  logger.info("server started", fields=[@log.field("port", "8080")])
}
```

Continue with the [Examples guide](./examples/index.md): console fields, file rotation, JSON configuration, and async lifecycle are each documented as a complete path.

## Support Status

- Current local verification covers `native`, `js`, `wasm`, and `wasm-gc` for the main `src` package and `src-async`
- `llvm` is still treated as experimental in the current release context and was not locally re-verified in the current environment
- The source packages still declare `wasm` support alongside `native`, `llvm`, `js`, and `wasm-gc`; see [`target-verification.md`](./api/target-verification.md) for the current release-facing verification boundary
- File output is a native capability; check `native_files_supported()` in cross-target code
- `src-async` is available, while `examples/async_basic` is still shipped as a native entry example

## Main Features

- Structured logs with levels, targets, messages, and fields
- Multiple outputs: console, JSON console, text console, and file
- Custom text formatting with templates, style tags, and color control
- Config-based builders: `build_logger(...)` and `build_async_logger(...)`
- Composition helpers: queue, filter, patch, fanout, split, callback
- Separate async package under `src-async`

## Documentation

- [Examples](./examples/index.md): complete application-facing usage flows
- [Extend](./extend/index.md): queueing, sink composition, formatting, and target boundaries
- [API index](./api/index.md): canonical API reference, organized as one public API per file
- [src package README](https://github.com/Nanaloveyuki/BitLogger/blob/main/src/README.mbt.md): package-level usage notes and target reminders
- [`docs/changes/`](./changes/): versioned release notes and publish-facing change summaries
- `docs/dev/`: developer reference material kept in the repository, intentionally excluded from the public static docs site

Common entry points: `text_console(...)`, `file(...)`, `with_queue(...)`, `build_logger(...)`, `build_async_logger(...)`
