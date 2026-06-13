---
name: runtime-sink-file-policy-matches-default
group: api
category: runtime
update-time: 20260613
description: Read whether the current runtime file policy still matches the RuntimeSink default policy.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-policy-matches-default

Read whether the current runtime file policy still matches the default policy of a `RuntimeSink`. This helper is useful for detecting operational drift on direct sink values.

### Interface

```moonbit
pub fn RuntimeSink::file_policy_matches_default(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose runtime policy drift should be checked.

#### output

- `Bool` - Whether the current runtime file policy still matches the default.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants compare current runtime file policy against their stored defaults.
- `QueuedFile` runtime variants forward the comparison from the wrapped inner `FileSink`.
- Non-file runtime variants return `false`.
- This helper is a compact drift signal when callers do not need to compare full policy objects directly.

### How to Use

Here are some specific examples provided.

#### When Need Drift Detection

When diagnostics should report whether file policy changed after startup:
```moonbit
let unchanged = sink.file_policy_matches_default()
```

In this example, the runtime sink exposes whether runtime file policy still matches the baseline.

#### When Gate Reset Logic

When code should only reset policy if drift exists:
```moonbit
if !sink.file_policy_matches_default() {
  ignore(sink.file_reset_policy())
}
```

In this example, policy reset only happens when runtime state diverged from defaults.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need the exact differences instead of a boolean drift signal, they should inspect both `file_policy()` and `file_default_policy()`.

### Notes

1. Use this helper for compact runtime policy drift checks.

2. It is especially useful before calling reset-style operations.
