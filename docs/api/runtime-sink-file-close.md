---
name: runtime-sink-file-close
group: api
category: runtime
update-time: 20260707
description: Close the file sink behind a RuntimeSink when one is present, with queued-file success tied to safe drain-flush-close behavior.
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

- `Bool` - Whether the file-specific close path succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants forward directly to `FileSink::close()`.
- `QueuedFile` runtime variants first drain the queue, then flush the wrapped file sink, then close it.
- For `QueuedFile`, the returned `Bool` is `true` only when that whole path succeeds and no new write, flush, or rotation failures are observed during the drain-flush-close step.
- Non-file runtime variants return `false`.
- After a file-backed runtime sink has already cleared its handle, later `file_close()` calls return `false`.

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

In this example, the result describes the file-specific close path rather than generic sink close behavior.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If the file handle was already closed earlier through this runtime sink or another facade sharing the same underlying file-backed state, the method returns `false`.

- If callers only need generic sink teardown, `close()` is the broader API.

- On queued file sinks, `true` still does not mean a stronger durability contract than the current backend can report; it means the safe drain-flush-close path completed without a newly observed file failure.

### Notes

1. Prefer this helper when direct runtime code specifically cares about file-backed shutdown.

2. Generic `close()` now uses the same safe queued-file teardown path.
