---
name: file-sink-async
group: api
category: sink
update-time: 20260825
description: Create a file sink from an async context using the native async filesystem interface.
key-word:
    - file
    - sink
    - async
    - public
---

## File-sink-async

Create a `FileSink` from an async context. The constructor opens the file with the native `moonbitlang/async/fs` interface and keeps the same rotation, policy, and failure-counter surface as `file_sink(...)`.

### Interface

```moonbit
pub async fn file_sink_async(
  path : String,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  formatter~ : RecordFormatter = fn(rec) { format_text(rec) },
) -> FileSink {}
```

#### input

- `path : String` - Destination file path.
- `append : Bool` - Whether writes append rather than truncate on the first open.
- `auto_flush : Bool` - Whether each async write requests an async file sync.
- `rotation : FileRotation?` - Optional size-based rotation policy.
- `formatter : RecordFormatter` - Formatter used to render each record.

#### output

- `FileSink` - A file sink ready for use by an async logger or direct async sink writes.

### Explanation

- Use this constructor when the caller is already running inside an async event loop.
- File writes, flushes, file-size checks, renames, removals, and rotation reopening use the async filesystem path.
- The returned sink implements `Sink::write_async(...)`; the synchronous `write(...)` surface remains available for synchronous callers.
- On non-native targets, the sink follows the existing unavailable-backend behavior.

### How to Use

```moonbit
let sink = file_sink_async("app.log", auto_flush=false)
let logger = async_logger(sink)
```

### Error Case

- If the initial async open fails, the returned sink is unavailable and increments `open_failures()`.
- Later async writes record write and rotation failures through the existing sink counters.

### Notes

1. Use `file_sink(...)` for synchronous construction outside an async event loop.

2. Pair this API with `native_files_supported()` when code must also compile for non-native targets.
