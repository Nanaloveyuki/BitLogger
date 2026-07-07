---
name: runtime-sink-file-policy-or-none
group: api
category: runtime
update-time: 20260707
description: Read the current runtime file policy from a RuntimeSink only when it is actually file-backed.
key-word:
    - runtime
    - sink
    - file
    - truthful
---

## Runtime-sink-file-policy-or-none

Read the current runtime file policy from a `RuntimeSink` only when it is actually file-backed.

This is the truthful companion to `file_policy()`. Prefer it for diagnostics and recovery logic that must avoid fallback policy objects.

### Interface

```moonbit
pub fn RuntimeSink::file_policy_or_none(self : RuntimeSink) -> FileSinkPolicy? {
```

#### input

- `self : RuntimeSink` - Runtime sink whose current file policy should be inspected.

#### output

- `FileSinkPolicy?` - `Some(policy)` when the runtime sink is file-backed, otherwise `None`.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return `Some(current_policy)`.
- `QueuedFile` runtime variants forward the wrapped inner file sink policy as `Some(current_policy)`.
- Non-file runtime variants return `None`.
- This helper is broader than `file_append_mode()` or `file_auto_flush()` because it returns the whole policy object without fallback synthesis.

### How to Use

Here are some specific examples provided.

#### When Need Truthful Policy Diagnostics

When diagnostics should inspect file policy only if file semantics exist:
```moonbit
match sink.file_policy_or_none() {
  Some(policy) => ignore(policy)
  None => ()
}
```

In this example, `None` means there is no real file policy to inspect.

#### When Need Compatibility-free Recovery Decisions

When recovery logic should not treat a fallback object as real state:
```moonbit
let maybe_policy = sink.file_policy_or_none()
```

In this example, callers can distinguish missing file semantics from a live policy snapshot.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `None`.

- If callers need default-policy comparison, pair it with `file_default_policy_or_none()`.

### Notes

1. Prefer this helper over `file_policy()` for truthful runtime diagnostics.

2. `file_policy()` remains available as the compatibility fallback API.
