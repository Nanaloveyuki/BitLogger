---
name: runtime-sink-file-reset-policy
group: api
category: runtime
update-time: 20260613
description: Reset the runtime file policy of a file-backed RuntimeSink back to its original defaults.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-reset-policy

Reset the runtime file policy of a `RuntimeSink` back to its original defaults. This helper restores append, auto-flush, and rotation policy together on direct sink values.

### Interface

```moonbit
pub fn RuntimeSink::file_reset_policy(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file policy should be restored.

#### output

- `Bool` - Whether the reset was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants restore their stored default file policy and return `true`.
- `QueuedFile` runtime variants forward the reset behavior to the wrapped inner `FileSink` and return `true`.
- Non-file runtime variants return `false`.
- This helper is the inverse of runtime policy drift, not a generic reopen or flush action.

### How to Use

Here are some specific examples provided.

#### When Need To Undo Runtime Policy Changes

When file policy should return to the original defaults captured by the runtime sink:
```moonbit
ignore(sink.file_reset_policy())
```

In this example, append, auto-flush, and rotation settings are restored together.

#### When Use Drift-aware Recovery

When reset should only happen after runtime changes:
```moonbit
if !sink.file_policy_matches_default() {
  ignore(sink.file_reset_policy())
}
```

In this example, reset is only applied when runtime policy has diverged.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need to restore only one setting, a narrower setter may be more appropriate than a full policy reset.

### Notes

1. Use this helper when the original bundled file policy should be restored intact.

2. It pairs naturally with `file_policy_matches_default()` and `file_default_policy()`.
