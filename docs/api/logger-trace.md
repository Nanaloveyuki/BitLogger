---
name: logger-trace
group: api
category: logging
update-time: 20260512
description: Emit a trace-level record through the logger using the lowest built-in severity shortcut.
key-word:
    - logger
    - trace
    - sync
    - public
---

## Logger-trace

Emit a trace-level record through the synchronous logger. This is the convenience wrapper for `log(Level::Trace, ...)`.

### Interface

```moonbit
pub fn[S : Sink] Logger::trace(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {}
```

#### input

- `self : Logger[S]` - Logger that should emit the trace record.
- `message : String` - Trace message text.
- `fields : Array[Field]` - Optional structured fields attached to the record.

#### output

- `Unit` - No return value. The record is handled according to the logger threshold and sink pipeline.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper delegates to `log(Level::Trace, ...)`.
- Trace is the lowest built-in severity and is often disabled in production.
- Per-call target override is not exposed here; use `log(...)` if that is needed.
- Context, filtering, patching, and queue wrappers still apply through the logger sink chain.

### How to Use

Here are some specific examples provided.

#### When Need Low-level Execution Tracing

When fine-grained flow diagnostics are useful:
```moonbit
logger.trace("entered reconciliation step")
```

In this example, trace intent is explicit and concise.

#### When Attach Structured Trace Context

When a trace event should include fields:
```moonbit
logger.trace("cache probe", fields=[field("key", "user:42")])
```

In this example, trace output stays lightweight while still carrying structured detail.

### Error Case

e.g.:
- If the logger minimum level is above `Trace`, the call returns without writing a record.

- If a per-call target override is required, this helper is too narrow and `log(...)` should be used instead.

### Notes

1. Prefer this helper when trace intent is clearer than a raw `log(Level::Trace, ...)` call.

2. Very verbose trace logging can become expensive even in a synchronous pipeline.

