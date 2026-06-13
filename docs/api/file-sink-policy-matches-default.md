---
name: file-sink-policy-matches-default
group: api
category: sink
update-time: 20260613
description: Read whether the current FileSink policy still matches its default policy.
key-word:
    - file
    - sink
    - policy
    - public
---

## File-sink-policy-matches-default

Read whether the current runtime file policy of a `FileSink` still matches its default policy. This helper is useful for detecting direct policy drift on the sink.

### Interface

```moonbit
pub fn FileSink::policy_matches_default(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink whose runtime policy drift should be checked.

#### output

- `Bool` - Whether the current runtime file policy still matches the default.

### Explanation

Detailed rules explaining key parameters and behaviors

- The method compares current append and auto-flush settings directly.
- Rotation drift is checked structurally, comparing `max_bytes` and `max_backups` when both sides are present.
- This helper is a compact drift signal when callers do not need to compare full policy objects directly.
- It does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Drift Detection

When diagnostics should report whether file policy changed after startup:
```moonbit
let unchanged = sink.policy_matches_default()
```

In this example, the direct sink exposes whether runtime file policy still matches the baseline.

#### When Gate Reset Logic

When code should only reset policy if drift exists:
```moonbit
if !sink.policy_matches_default() {
  sink.reset_policy()
}
```

In this example, policy reset only happens when runtime state diverged from defaults.

### Error Case

e.g.:
- If callers need the exact differences instead of a boolean drift signal, they should inspect both `policy()` and `default_policy()`.

- This helper only compares policy state; it does not report open, write, or flush failures.

### Notes

1. Use this helper for compact direct policy drift checks.

2. It is especially useful before calling reset-style operations.
