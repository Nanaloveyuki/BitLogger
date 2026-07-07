---
name: configured-logger-file-policy
group: api
category: runtime
update-time: 20260707
description: Read the current runtime file policy from a configured logger, with a compatibility fallback for non-file sinks.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-policy

Read the current runtime file policy from a `ConfiguredLogger`. This helper exposes the active append, auto-flush, and rotation settings as one policy object.

`file_policy()` is the compatibility form. For truthful file-semantics detection, prefer `file_policy_or_none()`.

### Interface

```moonbit
pub fn ConfiguredLogger::file_policy(self : ConfiguredLogger) -> FileSinkPolicy {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose current file policy should be inspected.

#### output

- `FileSinkPolicy` - Current runtime file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return their current runtime file policy through the wrapped `RuntimeSink`.
- Queued file sinks forward the policy from the wrapped inner file sink.
- Non-file sinks return the same neutral fallback policy value produced by `RuntimeSink::file_policy()`.
- This fallback keeps older callers source-compatible, but it is not a real file policy.
- New diagnostic or recovery code should prefer `file_policy_or_none()`.
- This helper is broader than `file_append_mode()` or `file_auto_flush()` because it returns the whole policy object.

### How to Use

Here are some specific examples provided.

#### When Need Full Runtime Policy Visibility

When diagnostics should inspect the active file policy as one object:
```moonbit
let policy = logger.file_policy()
```

In this example, append, flush, and rotation settings are read together.

#### When Compare Current And Default Policy

When runtime drift from defaults should be inspected explicitly:
```moonbit
let current = logger.file_policy()
let defaults = logger.file_default_policy()
```

In this example, callers can compare current runtime settings with the initial policy snapshot.

### Error Case

e.g.:
- If the configured sink is not file-backed, the return value is a neutral fallback policy rather than a real active file policy.

- If callers need a truthful file-semantics check, use `file_policy_or_none()`.

- If callers only need one field from the policy, a narrower helper may be simpler.

### Notes

1. Use this helper when file policy should be handled as one object.

2. Pair it with `file_set_policy(...)` for roundtrip-style policy management, or prefer `file_policy_or_none()` for truthful diagnostics.
