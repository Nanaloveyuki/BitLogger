---
name: file-sink-type
group: api
category: sink
update-time: 20260613
description: Public native file sink type used for file-backed synchronous logging with runtime policy and failure tracking.
key-word:
    - sink
    - file
    - type
    - public
---

## File-sink-type

`FileSink` is the public native file sink type used for file-backed synchronous logging. It is the concrete sink type returned by `file_sink(...)`, and it stores runtime file policy, availability state, formatter behavior, and failure counters.

### Interface

```moonbit
pub struct FileSink {
  path : String
  append : Ref[Bool]
  default_append : Bool
  handle : Ref[FileHandle?]
  formatter : RecordFormatter
  auto_flush : Ref[Bool]
  default_auto_flush : Bool
  rotation : Ref[FileRotation?]
  default_rotation : FileRotation?
  open_failures : Ref[Int]
  write_failures : Ref[Int]
  flush_failures : Ref[Int]
  rotation_failures : Ref[Int]
}
```

#### output

- `FileSink` - Public native file sink type with runtime policy, state, and failure tracking.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields cover path, append mode, handle state, formatter, auto-flush policy, optional rotation policy, and failure counters.
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
