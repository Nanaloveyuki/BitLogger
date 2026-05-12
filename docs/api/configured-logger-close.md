---
name: configured-logger-close
group: api
category: runtime
update-time: 20260512
description: Close the configured runtime logger sink and return whether the underlying sink reported a close action.
key-word:
    - logger
    - runtime
    - lifecycle
    - public
---

## Configured-logger-close

Close the sink behind a `ConfiguredLogger`. This helper is the config-driven runtime close surface for queue-backed or file-backed sinks.

### Interface

```moonbit
pub fn ConfiguredLogger::close(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose sink should be closed.

#### output

- `Bool` - Whether the underlying runtime sink reported a successful close action.

### Explanation

Detailed rules explaining key parameters and behaviors

- Queue-backed file sinks close the wrapped file sink.
- Plain file sinks forward directly to file close behavior.
- Console-style sinks usually report `true` because they do not have a meaningful close step.
- This helper delegates to `RuntimeSink::close(...)` through the configured logger wrapper.

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
- If the runtime sink has no real close action, the helper may still return `true` as a no-op success.

- If callers need a file-specific close path with queue flush nuances, `file_close()` may be the better API.

### Notes

1. This is the generic configured runtime close helper.

2. Prefer file-specific helpers when the sink shape is known to be file-backed.
