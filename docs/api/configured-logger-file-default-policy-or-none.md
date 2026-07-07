---
name: configured-logger-file-default-policy-or-none
group: api
category: runtime
update-time: 20260707
description: Read the default runtime file policy from a ConfiguredLogger only when it is actually file-backed.
key-word:
    - logger
    - runtime
    - file
    - truthful
---

## Configured-logger-file-default-policy-or-none

Read the default runtime file policy from a `ConfiguredLogger` only when it is actually file-backed.

This is the truthful companion to `file_default_policy()`. Prefer it when default-policy inspection should not fabricate a fallback object on non-file sinks.

### Interface

```moonbit
pub fn ConfiguredLogger::file_default_policy_or_none(self : ConfiguredLogger) -> FileSinkPolicy? {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose default file policy should be inspected.

#### output

- `FileSinkPolicy?` - `Some(policy)` when the configured sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return `Some(default_policy)` through the wrapped `RuntimeSink`.
- Queued file sinks forward the wrapped inner file sink default policy as `Some(default_policy)`.
- Non-file sinks return `None`.
- This helper is useful when callers need to compare runtime drift or restore defaults without fabricating file semantics.

### How to Use

Here are some specific examples provided.

#### When Need Truthful Baseline Policy Visibility

When tooling should inspect defaults only for real file-backed sinks:
```moonbit
let defaults = logger.file_default_policy_or_none()
```

In this example, `None` means the configured logger has no file default policy.

#### When Compare Current And Default Policy Truthfully

When diagnostics should avoid fallback policy objects:
```moonbit
match (logger.file_policy_or_none(), logger.file_default_policy_or_none()) {
  (Some(current), Some(defaults)) => ignore((current, defaults))
  _ => ()
}
```

In this example, comparisons happen only when real file semantics exist.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `None`.

- If callers only need a drift boolean, `file_policy_matches_default()` remains simpler.

### Notes

1. Prefer this helper over `file_default_policy()` for truthful runtime diagnostics.

2. `file_default_policy()` remains available as the compatibility fallback API.
