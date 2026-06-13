# BitLogger

BitLogger is a structured logging library for MoonBit projects.

- [Mooncake package page](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [Chinese README](../README.md)

## Overview

BitLogger gives you consistent levels, targets, structured fields, configurable text output, native file logging, and an async logging layer.

## Quick Start

```moonbit
let logger = build_logger(
  text_console(
    min_level=Level::Info,
    target="demo",
    text_formatter=TextFormatterConfig::new(show_timestamp=false, separator=" | "),
  ),
)

logger.info("starting", fields=[field("port", "8080")])
ignore(logger.flush())
```

Start with `console(...)`, `json_console(...)`, `text_console(...)`, or `file(...)`, then add `with_queue(...)` or `with_file_rotation(...)` only when needed.

Use `Logger::new(...)` when you want to assemble custom sink graphs directly.

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

## Examples

- `examples/console_basic/`: minimal console and JSON console example
- `examples/text_formatter/`: text formatting and template example
- `examples/style_tags/`: style tags and colored output example
- `examples/config_build/`: config-based build example
- `examples/presets/`: common preset combinations
- `examples/file_rotation/`: native file logging and rotation example
- `examples/async_basic/`: async logging example

## Documentation

- [API index](./api/index.md)
- [src package README](../src/README.mbt.md)

Common entry points: `text_console(...)`, `file(...)`, `with_queue(...)`, `build_logger(...)`, `build_async_logger(...)`
