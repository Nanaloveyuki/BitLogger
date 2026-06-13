---
name: file-sink-reset-policy
group: api
category: sink
update-time: 20260613
description: Reset the runtime file policy of a FileSink back to its original defaults.
key-word:
    - file
    - sink
    - reset
    - public
---

## File-sink-reset-policy

Reset the runtime file policy of a `FileSink` back to its original defaults. This helper restores append, auto-flush, and rotation policy together on the direct sink.

### Interface

```moonbit
pub fn FileSink::reset_policy(self : FileSink) -> Unit {
```

#### input

- `self : FileSink` - File sink whose file policy should be restored.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper restores the sink's stored default append, auto-flush, and rotation settings.
- It is the inverse of runtime policy drift, not a generic reopen or flush action.
- It changes policy only and does not reopen the sink automatically.

### How to Use

Here are some specific examples provided.

#### When Need To Undo Runtime Policy Changes

When direct file policy should return to the original configured defaults:
```moonbit
sink.reset_policy()
```

In this example, append, auto-flush, and rotation settings are restored together.

#### When Use Drift-aware Recovery

When reset should only happen after runtime changes:
```moonbit
if !sink.policy_matches_default() {
  sink.reset_policy()
}
```

In this example, reset is only applied when runtime policy has diverged.

### Error Case

e.g.:
- If callers need to restore only one setting, a narrower setter may be more appropriate than a full policy reset.

- This helper does not reopen the file or prove current availability.

### Notes

1. Use this helper when the original bundled file policy should be restored intact.

2. It pairs naturally with `policy_matches_default()` and `default_policy()`.
