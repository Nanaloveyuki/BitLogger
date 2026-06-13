---
name: configured-logger-file-reopen-truncate
group: api
category: runtime
update-time: 20260512
description: Reopen the file sink behind a configured runtime logger in truncate mode.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-reopen-truncate

Reopen the file sink behind a `ConfiguredLogger` in truncate mode. This helper is the explicit truncate-oriented recovery or reset shortcut.

### Interface

```moonbit
pub fn ConfiguredLogger::file_reopen_truncate(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file sink should be reopened in truncate mode.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain file sinks reopen in truncate mode through the wrapped `RuntimeSink`.
- Queued file sinks forward reopen behavior to the wrapped inner file sink.
- This helper is a specialized shortcut for a common reset-style reopen mode.
- Non-file sinks return `false`.

### How to Use

Here are some specific examples provided.

#### When Need A Fresh Output File

When a runtime file should be reopened from an empty state:
```moonbit
ignore(logger.file_reopen_truncate())
```

In this example, reopen behavior truncates the file before future writes continue.

#### When Want An Explicit Truncate Shortcut

When code should make destructive reopen intent obvious:
```moonbit
let ok = logger.file_reopen_truncate()
```

In this example, the call site expresses reset-style reopen behavior directly.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers want to preserve existing file content, `file_reopen_append()` is the correct API.

### Notes

1. Use this helper when starting from a fresh file is intentional.

2. Truncate-mode reopen is a stronger action than generic reopen recovery.
