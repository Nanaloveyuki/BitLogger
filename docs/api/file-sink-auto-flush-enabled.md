---
name: file-sink-auto-flush-enabled
group: api
category: sink
update-time: 20260613
description: Read whether auto-flush is currently enabled on a FileSink.
key-word:
    - file
    - sink
    - flush
    - public
---

## File-sink-auto-flush-enabled

Read whether auto-flush is currently enabled on a `FileSink`. This helper exposes one important direct durability policy flag on the concrete sink.

### Interface

```moonbit
pub fn FileSink::auto_flush_enabled(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink whose auto-flush policy should be inspected.

#### output

- `Bool` - Whether auto-flush is currently enabled.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method reads the sink's current runtime auto-flush policy.
- It exposes policy state only and does not force any flush action.
- Auto-flush affects whether writes attempt a flush after each rendered record.
- This helper does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Direct Durability Visibility

When diagnostics should expose whether each write auto-flushes:
```moonbit
let enabled = sink.auto_flush_enabled()
```

In this example, direct file durability policy is surfaced from the sink itself.

#### When Validate Policy Updates

When code should observe auto-flush after a setter call:
```moonbit
sink.set_auto_flush(true)
ignore(sink.auto_flush_enabled())
```

In this example, callers verify the updated policy on the concrete file sink.

### Error Case

e.g.:
- If callers need to actually flush the file, `flush()` is the operational API.

- This helper does not say whether the sink is open or whether prior flushes succeeded.

### Notes

1. Use this helper to inspect direct sink durability policy.

2. It complements `set_auto_flush(...)` rather than replacing real flush actions.
