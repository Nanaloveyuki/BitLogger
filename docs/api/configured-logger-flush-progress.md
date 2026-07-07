---
name: configured-logger-flush-progress
group: api
category: runtime
update-time: 20260707
description: Return a structured generic flush progress snapshot for a ConfiguredLogger through RuntimeSink without collapsing queue and plain-file fallback semantics into one Int.
key-word:
    - logger
    - runtime
    - flush
    - public
---

## Configured-logger-flush-progress

Return a structured generic flush progress snapshot for a `ConfiguredLogger`. This is the recommended configured runtime wrapper over `RuntimeSink::flush_progress(...)` when code wants truthful generic progress instead of the compatibility `Int` returned by `flush()`.

### Interface

```moonbit
pub fn ConfiguredLogger::flush_progress(self : ConfiguredLogger) -> RuntimeSinkProgress {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose generic flush progress should be observed.

#### output

- `RuntimeSinkProgress` - Structured progress snapshot returned by the wrapped `RuntimeSink::flush_progress(...)` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.flush_progress()`.
- Queue-wrapped sinks report queue advancement through `queue_advanced_count`.
- Plain file sinks report the generic fallback flush step through `file_flush_step_count`.
- Plain console-style sinks return a zeroed snapshot.
- This helper is the configured-logger entry point for the truthful generic progress surface introduced alongside the older compatibility `flush()` path.

### How to Use

Here are some specific examples provided.

#### When Need Recommended Generic Flush Progress On A Config-built Logger

When config-built runtime code should inspect flush progress explicitly:
```moonbit
let progress = logger.flush_progress()
```

In this example, the configured runtime logger reports structured progress without collapsing runtime-shape semantics.

#### When Need To Branch On Queue-backed Versus Plain-file Generic Progress

When application code should keep the config-built facade but still distinguish progress meaning:
```moonbit
let progress = logger.flush_progress()
if progress.queue_backed {
  println(progress.queue_advanced_count)
}
```

In this example, queue advancement remains explicit even though the logger was built from config.

### Error Case

e.g.:
- If the configured runtime sink shape has no flushable state, the snapshot simply reports zero counts.

- If callers need file-specific success semantics on a file-backed logger, `file_flush()` is the better API.

### Notes

1. Prefer `flush_progress()` over `flush()` in new configured-runtime code.

2. `flush()` is still available for compatibility with older code that expects one numeric count.
