---
name: configured-logger-flush
group: api
category: runtime
update-time: 20260707
description: Compatibility configured runtime flush helper that still returns one Int by collapsing generic queue progress and plain-file fallback steps.
key-word:
    - logger
    - runtime
    - flush
    - public
---

## Configured-logger-flush

Flush a `ConfiguredLogger` and return one compatibility count. This helper is still available for older code, but new configured-runtime code should prefer `flush_progress()` because it exposes queue advancement and plain-file fallback steps separately.

### Interface

```moonbit
pub fn ConfiguredLogger::flush(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose sink should be flushed.

#### output

- `Int` - Compatibility count returned by the wrapped `RuntimeSink::flush(...)` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.flush()`.
- Under the hood, `RuntimeSink::flush()` now rebuilds one compatibility count from `flush_progress()`.
- Queue-wrapped sinks still report queued-record consumption through that compatibility count.
- Plain file sinks still report the generic fallback flush step as `1` or `0`.
- Plain console-style sinks still return `0`.

### How to Use

Here are some specific examples provided.

#### When Need Explicit Queue Progress

When older code already expects one numeric flush count from a config-built logger:
```moonbit
ignore(logger.flush())
```

In this example, the configured runtime logger is flushed without changing the legacy return shape.

#### When Need A Post-write Flush Barrier

When code only needs a coarse non-zero check and does not care which runtime dimension advanced:
```moonbit
let flushed = logger.flush()
```

In this example, callers still get one compatibility count rather than a structured progress snapshot.

### Error Case

e.g.:
- If the configured runtime sink shape has no flushable state, the method may simply return `0`.

- If callers need truthful generic progress semantics, `flush_progress()` is the better API.

- If callers need bounded manual draining rather than generic flush behavior, `drain_progress(...)` is usually the better API.

- If callers need file-specific success semantics on a file-backed logger, `file_flush()` is the better API.

### Notes

1. Treat this method as a compatibility helper for older numeric code.

2. Prefer `flush_progress()` in new configured-runtime code.

3. The exact return value depends on which `RuntimeSink` variant the configured logger owns.
