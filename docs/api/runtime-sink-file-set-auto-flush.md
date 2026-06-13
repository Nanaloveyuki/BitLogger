---
name: runtime-sink-file-set-auto-flush
group: api
category: runtime
update-time: 20260613
description: Update the auto-flush policy used by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-set-auto-flush

Update the auto-flush policy used by a file-backed `RuntimeSink`. This helper changes direct runtime durability behavior without rebuilding or rewrapping the sink.

### Interface

```moonbit
pub fn RuntimeSink::file_set_auto_flush(self : RuntimeSink, enabled : Bool) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file auto-flush policy should change.
- `enabled : Bool` - New auto-flush setting.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants update the wrapped `FileSink` auto-flush policy and return `true`.
- `QueuedFile` runtime variants forward the update to the wrapped inner `FileSink` and return `true`.
- Non-file runtime variants return `false`.
- This helper changes policy only; it does not itself flush pending data.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Durability Tuning

When a file-backed runtime sink should start flushing each write automatically:
```moonbit
ignore(sink.file_set_auto_flush(true))
```

In this example, runtime durability policy is updated without rebuilding the sink.

#### When Need To Relax Flush Pressure On A Runtime Sink

When file writes should stop auto-flushing for throughput reasons:
```moonbit
let ok = sink.file_set_auto_flush(false)
```

In this example, the call site updates policy explicitly and can inspect the result.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need an immediate flush action, `file_flush()` is the operational API.

### Notes

1. Use this helper for direct runtime durability tuning on `RuntimeSink` values.

2. Pair it with `file_auto_flush()` to verify the active policy.
