---
name: configured-logger-file-reopen-append
group: api
category: runtime
update-time: 20260512
description: Reopen the file sink behind a configured runtime logger in append mode.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-reopen-append

Reopen the file sink behind a `ConfiguredLogger` in append mode. This helper is the explicit append-oriented recovery shortcut.

### Interface

```moonbit
pub fn ConfiguredLogger::file_reopen_append(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file sink should be reopened in append mode.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain file sinks reopen in append mode.
- Queued file sinks forward reopen behavior to the wrapped file sink.
- This helper is a specialized shortcut for a common reopen mode.
- Non-file sinks return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Append-preserving Recovery

When file logging should continue appending after a reopen:
```moonbit
ignore(logger.file_reopen_append())
```

In this example, reopen behavior is fixed to append mode.

#### When Want An Explicit Append Shortcut

When code should avoid manually setting append overrides:
```moonbit
let ok = logger.file_reopen_append()
```

In this example, the call site states append intent directly.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need truncate behavior instead, `file_reopen_truncate()` is the correct API.

### Notes

1. Use this helper for explicit append-mode reopen flows.

2. It is especially useful after transient file availability issues.
