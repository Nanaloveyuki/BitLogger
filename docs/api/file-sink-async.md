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

Create an `AsyncFileSink` from `Nanaloveyuki/BitLogger/src-async` in an async context. The sync root package intentionally does not expose this constructor or depend on the host async filesystem. The constructor opens the file with the native `moonbitlang/async/fs` interface and keeps the same rotation, policy, and failure-counter surface as `file_sink(...)`.

### Interface

```moonbit
pub async fn file_sink_async(
  path : String,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  formatter~ : RecordFormatter = fn(rec) { format_text(rec) },
) -> AsyncFileSink {}
```

#### input

- `path : String` - Destination file path.
- `append : Bool` - Whether writes append rather than truncate on the first open.
- `auto_flush : Bool` - Whether each async write requests an async file sync.
- `rotation : FileRotation?` - Optional size-based rotation policy.
- `formatter : RecordFormatter` - Formatter used to render each record.

#### output

- `AsyncFileSink` - A file sink ready for async logging and explicit async writes.

### Explanation

- Use this constructor when the caller is already running inside an async event loop; it opens through the async filesystem backend.
- `Sink::write_async(...)` and `flush_async()` use async filesystem operations. The synchronous `write(...)` and `flush()` methods remain synchronous operations over the shared file state; they do not turn the root `FileSink` API into an async API.
- Rotation and file maintenance performed by the async write path use the async filesystem backend.
- On non-native targets, the sink follows the existing unavailable-backend behavior.

### Deferred open

Config-built async loggers (`build_async_logger(...)` and its application/library/parse variants) create their file sink with a deferred handle and wrap it in `AsyncRuntimeSink`. The descriptor is acquired by the first async write:

- A deferred handle starts uninitialized and `file_available()` reports `true`, because the path is not yet known to be unusable.
- The first async write performs the async open. If that open fails, `open_failures` is incremented, the unusable handle is cleared so `file_available()` becomes `false`, and the write itself is also counted in `write_failures`.
- `flush_async()` on a deferred handle that was never written succeeds without touching the filesystem; it reports `false` and increments `flush_failures` once the handle is unavailable.

### Reopen

`AsyncFileSink::reopen*` are synchronous control operations over the shared file state. They install a deferred handle, so the file is reopened by the next async write rather than by the reopen call itself. This keeps the control surface identical to the root `FileSink` without turning `reopen` into an async API.

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
