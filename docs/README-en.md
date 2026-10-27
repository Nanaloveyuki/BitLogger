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
moon add Nanaloveyuki/BitLogger@0.9.1
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

Continue with the [Examples guide](./examples/index.md): console fields, file rotation, JSON or YAML configuration, and async lifecycle are each documented as a complete path.

## Support Status

- CI checks and tests `native`, `wasm`, `js`, and `wasm-gc` for the main `src` package and `src-async`
- `llvm` is still treated as experimental in the current release context and was not locally re-verified in the current environment
- The source packages still declare `wasm` support alongside `native`, `llvm`, `js`, and `wasm-gc`; see [`target-verification.md`](./api/target-verification.md) for the current release-facing verification boundary
- File output is a native capability; check `native_files_supported()` in cross-target code
- `src-async` is available, while `examples/async_basic` is still shipped as a native entry example

## Main Features

- Structured logs with levels, targets, messages, and fields
- Multiple outputs: console, JSON console, text console, and file
- Custom text formatting with templates, style tags, and color control
- Config-based builders: `build_logger(...)` and `build_async_logger(...)` accept JSON and YAML text
- Composition helpers: queue, filter, patch, fanout, split, callback
- Separate async package under `src-async`
- Trace-context binding through OpenTelemetry-normalized `trace_id`, `span_id`, `trace_flags`, and `trace_state` fields

## Documentation

- [Examples](./examples/index.md): complete application-facing usage flows
- [Extend](./extend/index.md): queueing, sink composition, formatting, and target boundaries
- [API index](./api/index.md): canonical API reference, organized as one public API per file
- [src package README](https://github.com/Nanaloveyuki/BitLogger/blob/main/src/README.mbt.md): package-level usage notes and target reminders
- [`docs/changes/`](./changes/): versioned release notes and publish-facing change summaries
- `docs/dev/`: developer reference material kept in the repository, intentionally excluded from the public static docs site

Common entry points: `text_console(...)`, `file(...)`, `with_queue(...)`, `build_logger(...)`, `build_async_logger(...)`

## Development

`.moonbit-toolchain` pins the compiler archive to `0.10.17+d971670cd` for local development and all MoonBit CI installations, including Windows. It installs the matching compiler, CLI, and core: `moonc v0.10.17+d971670cd (2026-10-23)` and `moon 0.1.20261023 (3778465 2026-10-23)`. The compiler and CLI have separate version numbers. Installation fails if the archive is unavailable; it does not fall back to latest.

Install from the repository root:

```bash
set -eo pipefail
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s -- "$(cat .moonbit-toolchain)"
export PATH="${MOON_HOME:-$HOME/.moon}/bin:$PATH"
moon version --all
moonc -v
moon update
```

For PowerShell, set `$env:MOONBIT_INSTALL_VERSION = (Get-Content .moonbit-toolchain -Raw).Trim()` before running the [official Windows installer](https://cli.moonbitlang.com/install/powershell.ps1).

Native builds require a C toolchain; Windows CI installs MSYS2 UCRT64 GCC and OpenSSL. JavaScript tests require Node.js; wasm and wasm-gc tests use the toolchain's moonrun. Native async tests and the async example run on Linux/macOS in the existing CI matrix. Native integration tests write to the repository's `logs/`; the file-rotation example creates `bitlogger-example.log` and rotated backups in the working directory. Both directories must be writable.

See the [root README development section](https://github.com/Nanaloveyuki/BitLogger/blob/main/README.md#开发) for native/cross-target/async verification and runnable example commands, and [CI](https://github.com/Nanaloveyuki/BitLogger/blob/main/.github/workflows/ci.yml) for the full workflow. These commands describe the new toolchain validation procedure, not a claim that validation has already run; historical release verification remains unchanged.

### 0.9.1 - 2026-10-27

- Pin development and CI to compiler `0.10.17+d971670cd` and CLI `0.1.20261023`. Third-party dependencies, including `moonbitlang/async@0.22.4`, are unchanged.
- Replace deprecated timestamp conversion with `Json(value)`, preserving the UInt64 JSON string representation.
