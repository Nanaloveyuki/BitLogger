---
name: configured-logger-close
group: api
category: runtime
update-time: 20260707
description: Close the configured runtime logger sink and return whether the wrapped RuntimeSink close path succeeded.
key-word:
    - logger
    - runtime
    - lifecycle
    - public
---

## Configured-logger-close

Close the sink behind a `ConfiguredLogger`. This helper is the configured logger wrapper over `RuntimeSink::close(...)` for config-driven runtime teardown.

### Interface

```moonbit
pub fn ConfiguredLogger::close(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose sink should be closed.

#### output

- `Bool` - Whether the wrapped `RuntimeSink::close(...)` call reported a successful close path.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.close()`.
- Plain file sinks forward to `FileSink::close()` through `RuntimeSink`.
- Queue-backed file sinks now follow the same safe teardown path as `file_close()`: they first try to drain the queue, then flush the wrapped inner file sink, then close it.
- On queued file sinks, the returned `Bool` is `true` only when that whole teardown path succeeds without introducing new file failures.
- Plain console-style sinks return `true` as a no-op success because they do not expose a meaningful close step here.
- Queue-wrapped console-style sinks now use drain-first teardown before returning `true`.
- For `QueuedConsole`, `QueuedJsonConsole`, and `QueuedTextConsole`, success means the queued backlog was consumed to zero.
- For file-backed configured loggers, later `close()` calls return `false` after the wrapped file handle has already been cleared.

### How to Use

Here are some specific examples provided.

#### When Need Config-driven Runtime Teardown

When a config-built logger should release its sink resources:
```moonbit
ignore(logger.close())
```

In this example, sink teardown happens through the configured logger facade.

#### When Need To Observe Close Outcome

When application code wants a success flag from runtime close behavior:
```moonbit
let closed = logger.close()
```

In this example, callers can branch on the reported close result.

### Error Case

e.g.:
- If the configured runtime sink shape has no real close action, the helper may still return `true` as a no-op success.

- If the configured logger shares the same wrapped runtime sink state with another facade and one path already closed that file-backed sink, a later close attempt returns `false`.

- If callers need a file-specific close path with queue flush nuances, `file_close()` may still be the clearer API.

- On queued file sinks, `true` still does not mean the records are guaranteed to be durable beyond what the current backend can report; it means the queue-drain, file-flush, and file-close path completed without a newly observed file failure.

- On queued non-file sinks, `true` means the queued backlog was consumed before teardown completed.

### Notes

1. This is the generic configured runtime close helper.

2. Generic `close()` is now safe for queue-backed runtime sinks and no longer skips queued records silently.

3. Converting the same configured logger through wrapper paths such as library projection still shares the wrapped runtime sink state, so close effects are visible across those facades.
