---
name: file-sink
group: api
category: sink
update-time: 20260512
description: Create a native file sink with append, auto-flush, rotation, reopen, and runtime observability helpers.
key-word:
    - file
    - sink
    - native
    - public
---

## File-sink

Create a native file sink for text-oriented or custom-formatted file logging. This API includes lifecycle controls, rotation configuration, reopen behavior, policy inspection, and failure counters.

### Interface

```moonbit
pub fn file_sink(
  path : String,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  formatter~ : RecordFormatter = fn(rec) { format_text(rec) },
) -> FileSink {}
```

#### input

- `path : String` - Destination file path.
- `append : Bool` - Whether opening/reopening should append rather than truncate.
- `auto_flush : Bool` - Whether flush is attempted after each write.
- `rotation : FileRotation?` - Optional size-based rotation policy.
- `formatter : RecordFormatter` - Formatter used to render each record before writing.

#### output

- `FileSink` - A native-only sink with write, flush, close, reopen, policy, and state helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- This sink is designed for host-file capable backends, with current local verification centered on `native`.
- `llvm` should be treated as experimental in the current release context and was not successfully re-verified in this environment.
- The `src` library is still designed for multi-target compilation, but file sink availability remains backend-sensitive inside that broader portable surface.
- `append` is persistent policy state and also affects later reopen behavior.
- `auto_flush` trades durability for more flush work per record.
- Rotation is currently size-based and rename-retention-oriented, not time-based.

### How to Use

Here are some specific examples provided.

#### When Need Persistent Local Logs

When logs should be written to a host filesystem:
```moonbit
if native_files_supported() {
  let sink = file_sink("app.log")
  let logger = Logger::new(sink, target="file")
  logger.info("started")
  ignore(sink.flush())
}
```

In this example, the sink writes normal text-formatted records to `app.log`.

And capability detection prevents non-native misuse.

#### When Need Rotation And Runtime Inspection

When you want bounded local log retention plus observability:
```moonbit
let sink = file_sink("app.log", rotation=Some(file_rotation(1024, max_backups=3)))
let state = sink.state()
```

In this example, rotation policy and sink health can both be read through runtime helpers.

### Error Case

e.g.:
- If the backend is non-native, file availability is not provided and callers should not expect writes to succeed.

- If open, write, flush, or rotation fails, the sink records failure counters instead of exposing a large exception surface.

### Notes

1. Always pair this API with `native_files_supported()` in cross-target code.

2. Prefer `state()`, `policy()`, and failure counters when integrating diagnostics.

3. Non-native targets can still compile code referencing this API, but callers should treat actual file availability and successful writes as target-sensitive runtime behavior.

4. See [target-verification.md](./target-verification.md) for the current verification boundary between design intent and locally re-checked targets.
