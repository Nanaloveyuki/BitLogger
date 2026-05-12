---
name: configured-logger-file-reset-policy
group: api
category: runtime
update-time: 20260512
description: Reset the runtime file policy of a configured file-backed logger back to its original defaults.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-reset-policy

Reset the runtime file policy of a `ConfiguredLogger` back to its original defaults. This helper restores append, auto-flush, and rotation policy together.

### Interface

```moonbit
pub fn ConfiguredLogger::file_reset_policy(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file policy should be restored.

#### output

- `Bool` - Whether the reset was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks restore their stored default file policy.
- Queued file sinks forward the reset behavior to the wrapped file sink.
- Non-file sinks return `false`.
- This helper is the inverse of runtime policy drift, not a generic reopen or flush action.

### How to Use

Here are some specific examples provided.

#### When Need To Undo Runtime Policy Changes

When file policy should return to the original configured defaults:
```moonbit
ignore(logger.file_reset_policy())
```

In this example, append, auto-flush, and rotation settings are restored together.

#### When Use Drift-aware Recovery

When reset should only happen after runtime changes:
```moonbit
if !logger.file_policy_matches_default() {
  ignore(logger.file_reset_policy())
}
```

In this example, reset is only applied when runtime policy has diverged.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need to restore only one setting, a narrower setter may be more appropriate than a full policy reset.

### Notes

1. Use this helper when the original bundled file policy should be restored intact.

2. It pairs naturally with `file_policy_matches_default()` and `file_default_policy()`.
