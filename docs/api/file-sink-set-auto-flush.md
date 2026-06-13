---
name: file-sink-set-auto-flush
group: api
category: sink
update-time: 20260613
description: Update the auto-flush policy used by a FileSink.
key-word:
    - file
    - sink
    - flush
    - public
---

## File-sink-set-auto-flush

Update the auto-flush policy used by a `FileSink`. This helper changes direct runtime durability behavior without rebuilding the sink.

### Interface

```moonbit
pub fn FileSink::set_auto_flush(self : FileSink, enabled : Bool) -> Unit {
```

#### input

- `self : FileSink` - File sink whose auto-flush policy should change.
- `enabled : Bool` - New auto-flush setting.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method updates runtime policy only.
- It does not itself flush pending data.
- The new value affects whether later writes attempt a flush after each rendered record.
- Existing path, append policy, and rotation policy are left unchanged.

### How to Use

Here are some specific examples provided.

#### When Need Direct Durability Tuning

When a concrete file sink should start flushing each write automatically:
```moonbit
sink.set_auto_flush(true)
```

In this example, runtime policy is updated without rebuilding the sink.

#### When Need To Relax Flush Pressure

When a file sink should stop auto-flushing for throughput reasons:
```moonbit
sink.set_auto_flush(false)
```

In this example, the call site updates policy explicitly on the direct file sink.

### Error Case

e.g.:
- If callers need an immediate flush action, `flush()` is the operational API.

- This helper does not report whether previous writes or flushes succeeded.

### Notes

1. Use this helper for direct runtime durability tuning.

2. Pair it with `auto_flush_enabled()` to verify the active policy.
