---
name: runtime-sink-file-default-policy-or-none
group: api
category: runtime
update-time: 20260707
description: Read the default runtime file policy from a RuntimeSink only when it is actually file-backed.
key-word:
    - runtime
    - sink
    - file
    - truthful
---

## Runtime-sink-file-default-policy-or-none

Read the default runtime file policy from a `RuntimeSink` only when it is actually file-backed.

This is the truthful companion to `file_default_policy()`. Prefer it when default-policy inspection should not fabricate a fallback object on non-file sinks.

### Interface

```moonbit
pub fn RuntimeSink::file_default_policy_or_none(self : RuntimeSink) -> FileSinkPolicy? {
```

#### input

- `self : RuntimeSink` - Runtime sink whose default file policy should be inspected.

#### output

- `FileSinkPolicy?` - `Some(policy)` when the runtime sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return `Some(default_policy)`.
- `QueuedFile` runtime variants forward the wrapped inner file sink default policy as `Some(default_policy)`.
- Non-file runtime variants return `None`.
- This helper is useful when callers need to compare runtime drift or restore defaults without fabricating file semantics.

### How to Use

Here are some specific examples provided.

#### When Need Truthful Baseline Policy Visibility

When tooling should inspect defaults only for real file-backed sinks:
```moonbit
let defaults = sink.file_default_policy_or_none()
```

In this example, `None` means the runtime sink has no file default policy.

#### When Compare Current And Default Policy Truthfully

When diagnostics should avoid fallback policy objects:
```moonbit
match (sink.file_policy_or_none(), sink.file_default_policy_or_none()) {
  (Some(current), Some(defaults)) => ignore((current, defaults))
  _ => ()
}
```

In this example, comparisons happen only when real file semantics exist.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `None`.

- If callers only need a drift boolean, `file_policy_matches_default()` remains simpler.

### Notes

1. Prefer this helper over `file_default_policy()` for truthful runtime diagnostics.

2. `file_default_policy()` remains available as the compatibility fallback API.
