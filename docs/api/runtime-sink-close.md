---
name: runtime-sink-close
group: api
category: runtime
update-time: 20260613
description: Close a RuntimeSink and report whether the underlying sink performed a successful close action.
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

- `Bool` - Whether the concrete runtime sink reported a successful close action.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain console-style runtime sinks return `true` because they do not have a meaningful close step here.
- Plain file runtime sinks forward directly to `FileSink::close()`.
- Queued file runtime sinks close the wrapped file sink rather than only the queue wrapper.
- Queue-wrapped console-style runtime sinks return `true` as a no-op success.
- This method is the direct sink-level API used by `ConfiguredLogger::close(...)`.

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

- If callers know they are working with a direct `FileSink`, `FileSink::close()` is the narrower API.

### Notes

1. Use this helper when code is managing a `RuntimeSink` value directly.

2. `ConfiguredLogger::close(...)` is the higher-level wrapper for config-built loggers.
