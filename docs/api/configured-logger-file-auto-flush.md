---
name: configured-logger-file-auto-flush
group: api
category: runtime
update-time: 20260512
description: Read whether the configured runtime file sink currently has auto-flush enabled.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-auto-flush

Read whether auto-flush is currently enabled on a `ConfiguredLogger` file sink. This helper exposes one important runtime durability policy flag.

### Interface

```moonbit
pub fn ConfiguredLogger::file_auto_flush(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose auto-flush policy should be inspected.

#### output

- `Bool` - Whether auto-flush is currently enabled.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks report their current auto-flush policy through the wrapped `RuntimeSink`.
- Queued file sinks forward the policy from the wrapped inner file sink.
- Non-file sinks return `false`.
- This helper exposes policy state only and does not force any flush action.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Durability Visibility

When diagnostics should expose whether each write auto-flushes:
```moonbit
let enabled = logger.file_auto_flush()
```

In this example, runtime file durability policy is surfaced directly.

#### When Validate Policy Updates

When code should observe auto-flush after a setter call:
```moonbit
ignore(logger.file_set_auto_flush(true))
ignore(logger.file_auto_flush())
```

In this example, callers verify the updated policy.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need to actually flush the file, `file_flush()` is the operational API.

### Notes

1. Use this helper to inspect runtime durability policy.

2. It complements `file_set_auto_flush(...)` rather than replacing real flush actions.
