---
name: file-sink-type
group: api
category: sink
update-time: 20260707
description: Public file sink type re-exported from file_runtime for file-backed synchronous logging.
key-word:
    - sink
    - file
    - type
    - public
---

## File-sink-type

`FileSink` is the public file sink type used for file-backed synchronous logging. On the root `src` facade, it is re-exported from `src/file_runtime`, which is the real owner of the concrete sink behavior type.

### Interface

```moonbit
pub using @file_runtime { type FileSink }
```

#### output

- `FileSink` - Public native file sink type with runtime policy, state, and failure tracking.

### Explanation

Detailed rules explaining key parameters and behaviors

- This root surface is a re-export of the concrete `@file_runtime.FileSink` type.
- The struct intentionally hides its fields; callers interact through methods such as `flush()`, `close()`, `reopen()`, `policy()`, and `state()`.
- File model companions such as `FileRotation`, `FileSinkPolicy`, `FileSinkState`, and `RuntimeFileState` are owned by `@file_model`, not by `FileSink` itself.
- `file_sink(...)` constructs this type directly from path and policy inputs.
- The type exposes runtime helpers such as `flush()`, `close()`, `reopen()`, `policy()`, `state()`, and failure-counter accessors.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Native File Sink Value

When code should keep the concrete file sink type visible:
```moonbit
let sink : FileSink = file_sink("app.log")
```

In this example, the sink value stays explicit and keeps the file-backed runtime controls available.

#### When Need A Typed File-backed Logger

When logging should preserve the native file sink type in the logger:
```moonbit
let logger : Logger[FileSink] = Logger::new(file_sink("app.log"), target="file")
```

In this example, the concrete file sink remains part of the logger type.

### Error Case

e.g.:
- `FileSink` itself does not have a runtime failure mode.

- Actual file availability, writes, flushes, and reopen behavior still depend on backend support and filesystem state.

### Notes

1. Use `file_sink(...)` when you need a value of this type.

2. Use `FileSinkState`, `FileSinkPolicy`, and `RuntimeFileState` when you need exported snapshots or higher-level diagnostics rather than the live sink type itself.
