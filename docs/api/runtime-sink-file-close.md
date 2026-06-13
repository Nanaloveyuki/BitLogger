---
name: runtime-sink-file-close
group: api
category: runtime
update-time: 20260613
description: Close the file sink behind a RuntimeSink when one is present.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-close

Close the file sink behind a `RuntimeSink`. This helper is the direct file-specific runtime close surface for code that owns a sink value instead of a `ConfiguredLogger`.

### Interface

```moonbit
pub fn RuntimeSink::file_close(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file sink should be closed.

#### output

- `Bool` - Whether the underlying file close succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants forward directly to `FileSink::close()`.
- `QueuedFile` runtime variants first attempt `sink.flush()` on the queue wrapper, then call `sink.sink.close()` on the wrapped file sink.
- For `QueuedFile`, the queue flush result is ignored and the returned `Bool` comes from the inner file close.
- Non-file runtime variants return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Direct File-specific Runtime Teardown

When code holds a file-backed `RuntimeSink` directly and should close its file handle explicitly:
```moonbit
ignore(sink.file_close())
```

In this example, file teardown happens through the runtime sink itself.

#### When Need A File-specific Close Result

When application code wants the direct file close outcome:
```moonbit
let closed = sink.file_close()
```

In this example, the result describes file close behavior rather than generic sink close behavior.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers only need generic sink teardown, `close()` is the broader API.

### Notes

1. Prefer this helper when direct runtime code specifically cares about file-backed shutdown.

2. Queued file sinks may flush pending records before closing the file.
