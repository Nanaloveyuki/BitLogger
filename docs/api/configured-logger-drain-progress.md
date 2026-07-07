---
name: configured-logger-drain-progress
group: api
category: runtime
update-time: 20260707
description: Return a structured generic drain progress snapshot for a ConfiguredLogger through RuntimeSink without collapsing queue and plain-file fallback semantics into one Int.
key-word:
    - logger
    - runtime
    - drain
    - public
---

## Configured-logger-drain-progress

Return a structured generic drain progress snapshot for a `ConfiguredLogger`. This is the recommended configured runtime wrapper over `RuntimeSink::drain_progress(...)` when code wants truthful generic progress instead of the compatibility `Int` returned by `drain()`.

### Interface

```moonbit
pub fn ConfiguredLogger::drain_progress(
  self : ConfiguredLogger,
  max_items~ : Int = -1,
) -> RuntimeSinkProgress {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose generic drain progress should be observed.
- `max_items : Int` - Optional upper bound on drained queued items. Negative values mean no explicit bound.

#### output

- `RuntimeSinkProgress` - Structured progress snapshot returned by the wrapped `RuntimeSink::drain_progress(...)` call.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates directly to `self.sink.drain_progress(max_items=max_items)`.
- Queue-wrapped sinks report drained queued items through `queue_advanced_count`.
- Plain file sinks report the generic fallback flush step through `file_flush_step_count`.
- Plain console-style sinks return a zeroed snapshot.
- This helper keeps configured-runtime drain behavior explicit without forcing callers to interpret one mixed `Int`.

### How to Use

Here are some specific examples provided.

#### When Need Recommended Bounded Generic Drain Progress On A Config-built Logger

When queued config-built output should be advanced in chunks with explicit semantics:
```moonbit
let progress = logger.drain_progress(max_items=16)
```

In this example, queue advancement and plain-file fallback stay separated.

#### When Need Full Manual Generic Drain Progress

When config-built support code should empty runtime queue work while keeping shape information:
```moonbit
let progress = logger.drain_progress()
```

In this example, the structured result still tells whether the logger was queue-backed or plain file-backed.

### Error Case

e.g.:
- If the configured runtime sink is not queue-backed, the snapshot may stay zeroed or use the plain-file fallback field.

- If callers need file-specific success semantics after queue delivery, `file_flush()` is the better API.

### Notes

1. Prefer `drain_progress()` over `drain()` in new configured-runtime code.

2. Use `pending_count()` together with this helper when remaining backlog should also be observed.
