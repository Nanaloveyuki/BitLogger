---
name: configured-logger-flush
group: api
category: runtime
update-time: 20260512
description: Flush a configured runtime logger and return how many queued or file-backed operations were advanced.
key-word:
    - logger
    - runtime
    - flush
    - public
---

## Configured-logger-flush

Flush a `ConfiguredLogger` and return how much work was advanced. This is the main runtime helper for forcing queued or file-backed logger output to move forward after config-driven construction.

### Interface

```moonbit
pub fn ConfiguredLogger::flush(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose sink should be flushed.

#### output

- `Int` - Count of flushed or drained items as reported by the runtime sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- For queue-wrapped sinks, this forwards to the queue drain/flush behavior.
- For plain file sinks, the return value reflects whether a file flush happened.
- For plain console-style sinks, the result is typically `0` because there is no meaningful buffered flush step.
- This helper delegates to `RuntimeSink::flush(...)` through the configured logger wrapper.

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
- If the configured sink has no flushable buffering, the method may simply return `0`.

- If callers need bounded manual draining rather than generic flush behavior, `drain(...)` is the better API.

### Notes

1. Use this helper after config-driven logger construction when explicit runtime flushing matters.

2. The exact return value depends on the underlying runtime sink shape.
