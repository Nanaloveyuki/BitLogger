---
name: configured-logger-file-policy-or-none
group: api
category: runtime
update-time: 20260707
description: Read the current runtime file policy from a ConfiguredLogger only when it is actually file-backed.
key-word:
    - logger
    - runtime
    - file
    - truthful
---

## Configured-logger-file-policy-or-none

Read the current runtime file policy from a `ConfiguredLogger` only when it is actually file-backed.

This is the truthful companion to `file_policy()`. Prefer it for diagnostics and recovery logic that must avoid fallback policy objects.

### Interface

```moonbit
pub fn ConfiguredLogger::file_policy_or_none(self : ConfiguredLogger) -> FileSinkPolicy? {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose current file policy should be inspected.

#### output

- `FileSinkPolicy?` - `Some(policy)` when the configured sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return `Some(current_policy)` through the wrapped `RuntimeSink`.
- Queued file sinks forward the wrapped inner file sink policy as `Some(current_policy)`.
- Non-file sinks return `None`.
- This helper is broader than `file_append_mode()` or `file_auto_flush()` because it returns the whole policy object without fallback synthesis.

### How to Use

Here are some specific examples provided.

#### When Need Truthful Policy Diagnostics

When diagnostics should inspect file policy only if file semantics exist:
```moonbit
match logger.file_policy_or_none() {
  Some(policy) => ignore(policy)
  None => ()
}
```

In this example, `None` means there is no real file policy to inspect.

#### When Need Compatibility-free Recovery Decisions

When recovery logic should not treat a fallback object as real state:
```moonbit
let maybe_policy = logger.file_policy_or_none()
```

In this example, callers can distinguish missing file semantics from a live policy snapshot.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `None`.

- If callers need default-policy comparison, pair it with `file_default_policy_or_none()`.

### Notes

1. Prefer this helper over `file_policy()` for truthful runtime diagnostics.

2. `file_policy()` remains available as the compatibility fallback API.
