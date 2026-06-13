---
name: configured-logger-flush
group: api
category: runtime
update-time: 20260613
description: Flush a configured runtime logger and return how many queued or file-backed operations were advanced through RuntimeSink.
key-word:
    - logger
    - runtime
    - flush
    - public
---

## Configured-logger-flush

Flush a `ConfiguredLogger` and return how much work was advanced. This is the configured logger wrapper over `RuntimeSink::flush(...)` for forcing queued or file-backed output to move forward after config-driven construction.

### Interface

```moonbit
pub fn ConfiguredLogger::flush(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose sink should be flushed.

#### output

- `Int` - Count returned by the wrapped `RuntimeSink::flush(...)` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.flush()`.
- Queue-wrapped sinks forward to the concrete queue sink's `flush()` behavior.
- Plain file sinks call `FileSink::flush()` through `RuntimeSink` and convert the boolean result into `1` or `0`.
- Plain console-style sinks return `0` because they do not expose a meaningful buffered flush step here.

### How to Use

Here are some specific examples provided.

#### When Need Explicit Queue Progress

When config-built queue output should be advanced manually:
```moonbit
ignore(logger.flush())
```

In this example, the configured runtime logger is flushed without reaching into the sink directly.

#### When Need A Post-write Flush Barrier

When a service wants stronger delivery behavior after a burst of writes:
```moonbit
let flushed = logger.flush()
```

In this example, callers can observe how much work was advanced by the flush request.

### Error Case

e.g.:
- If the configured runtime sink shape has no flushable state, the method may simply return `0`.

- If callers need bounded manual draining rather than generic flush behavior, `drain(...)` is the better API.

### Notes

1. Use this helper after config-driven logger construction when explicit runtime flushing matters.

2. The exact return value depends on which `RuntimeSink` variant the configured logger owns.
