---
name: runtime-sink-file-auto-flush
group: api
category: runtime
update-time: 20260613
description: Read whether the file-backed RuntimeSink currently has auto-flush enabled.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-auto-flush

Read whether auto-flush is currently enabled on a file-backed `RuntimeSink`. This helper exposes one important direct runtime durability policy flag without going through `ConfiguredLogger`.

### Interface

```moonbit
pub fn RuntimeSink::file_auto_flush(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file auto-flush policy should be inspected.

#### output

- `Bool` - Whether auto-flush is currently enabled.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report the current auto-flush policy from the wrapped `FileSink`.
- `QueuedFile` runtime variants forward the policy from the wrapped inner `FileSink`.
- Non-file runtime variants return `false`.
- This helper exposes policy state only and does not force any flush action.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Durability Visibility

When code owns a `RuntimeSink` directly and should expose whether each file write auto-flushes:
```moonbit
let enabled = sink.file_auto_flush()
```

In this example, runtime file durability policy is surfaced without going through a logger wrapper.

#### When Validate Direct Policy Updates

When code should observe auto-flush after a direct runtime setter call:
```moonbit
ignore(sink.file_set_auto_flush(true))
ignore(sink.file_auto_flush())
```

In this example, callers verify the updated policy on the runtime sink itself.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need to actually flush file output, `file_flush()` is the operational API.

### Notes

1. Use this helper to inspect direct runtime durability policy on `RuntimeSink` values.

2. It complements `file_set_auto_flush(...)` rather than replacing real flush actions.
