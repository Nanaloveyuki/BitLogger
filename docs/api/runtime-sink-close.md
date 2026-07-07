---
name: runtime-sink-close
group: api
category: runtime
update-time: 20260707
description: Close a RuntimeSink and report whether the concrete close path succeeded.
key-word:
    - runtime
    - sink
    - lifecycle
    - public
---

## Runtime-sink-close

Close a `RuntimeSink`. This is the direct runtime sink lifecycle API behind configured logger close behavior.

### Interface

```moonbit
pub fn RuntimeSink::close(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose underlying resources should be closed.

#### output

- `Bool` - Whether the concrete runtime sink reported a successful close path.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain console-style runtime sinks return `true` because they do not have a meaningful close step here.
- Plain file runtime sinks forward directly to `FileSink::close()`.
- Queued file runtime sinks now follow the same safe teardown path as `file_close()`: they first try to drain the queue, then flush the wrapped file sink, then close it.
- On `QueuedFile`, the returned `Bool` is `true` only when that whole teardown path succeeds without introducing new file failures.
- Queue-wrapped console-style runtime sinks also use drain-first teardown.
- For `QueuedConsole`, `QueuedJsonConsole`, and `QueuedTextConsole`, `close()` consumes pending queue items before reporting success.
- Because these wrapped console-style sinks do not expose an additional close-failure channel, success for these variants means the backlog was drained to zero.
- This method is the direct sink-level API used by `ConfiguredLogger::close(...)`.
- For file-backed runtime sinks, later `close()` calls return `false` after the handle has already been cleared.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Teardown

When code owns a `RuntimeSink` and should release its underlying resources:
```moonbit
ignore(sink.close())
```

In this example, sink teardown happens without going through a logger wrapper.

#### When Need To Observe Close Outcome

When application code wants a success flag from the direct runtime sink:
```moonbit
let closed = sink.close()
```

In this example, callers can branch on the reported close result.

### Error Case

e.g.:
- If the runtime sink shape has no real close action, the method may still return `true` as a no-op success.

- If a file-backed runtime sink was already closed earlier through this sink or another facade sharing the same underlying state, a later close attempt returns `false`.

- If callers know they are working with a direct `FileSink`, `FileSink::close()` is the narrower API.

- On queued file sinks, `true` still does not mean the records are guaranteed to be durable beyond what the current backend can report; it means the queue-drain, file-flush, and file-close path completed without a newly observed file failure.

- On queued non-file sinks, `true` means the queued backlog was consumed before teardown completed.

### Notes

1. Use this helper when code is managing a `RuntimeSink` value directly.

2. Generic `close()` is now safe for queue-backed runtime sinks and no longer skips queued records silently.

3. `ConfiguredLogger::close(...)` is the higher-level wrapper for config-built loggers.
