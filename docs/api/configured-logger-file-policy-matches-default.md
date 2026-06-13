---
name: configured-logger-file-policy-matches-default
group: api
category: runtime
update-time: 20260512
description: Read whether the current runtime file policy still matches the configured logger default policy.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-policy-matches-default

Read whether the current runtime file policy still matches the default policy of a `ConfiguredLogger`. This helper is useful for detecting operational drift.

### Interface

```moonbit
pub fn ConfiguredLogger::file_policy_matches_default(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose runtime policy drift should be checked.

#### output

- `Bool` - Whether the current runtime file policy still matches the default.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks compare current runtime file policy against their stored defaults through the wrapped `RuntimeSink`.
- Queued file sinks forward the comparison from the wrapped inner file sink.
- Non-file sinks return `false`.
- This helper is a compact drift signal when callers do not need to compare full policy objects directly.

### How to Use

Here are some specific examples provided.

#### When Need Drift Detection

When diagnostics should report whether file policy changed after startup:
```moonbit
let unchanged = logger.file_policy_matches_default()
```

In this example, the configured logger exposes whether runtime file policy still matches the baseline.

#### When Gate Reset Logic

When code should only reset policy if drift exists:
```moonbit
if !logger.file_policy_matches_default() {
  ignore(logger.file_reset_policy())
}
```

In this example, policy reset only happens when runtime state diverged from defaults.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need the exact differences instead of a boolean drift signal, they should inspect both `file_policy()` and `file_default_policy()`.

### Notes

1. Use this helper for compact runtime policy drift checks.

2. It is especially useful before calling reset-style operations.
