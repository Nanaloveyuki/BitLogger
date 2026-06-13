---
name: file-sink-policy-method
group: api
category: sink
update-time: 20260613
description: Read the current runtime file policy from a FileSink.
key-word:
    - file
    - sink
    - policy
    - public
---

## File-sink-policy-method

Read the current runtime file policy from a `FileSink`. This helper exposes the active append, auto-flush, and rotation settings as one policy object on the concrete sink.

### Interface

```moonbit
pub fn FileSink::policy(self : FileSink) -> FileSinkPolicy {
```

#### input

- `self : FileSink` - File sink whose current file policy should be inspected.

#### output

- `FileSinkPolicy` - Current runtime file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned policy is constructed from the sink's current append, auto-flush, and rotation settings.
- This helper is broader than `append_mode()` or `auto_flush_enabled()` because it returns the whole policy object.
- It is observation-only and does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Full Runtime Policy Visibility

When diagnostics should inspect the active file policy as one object:
```moonbit
let policy = sink.policy()
```

In this example, append, flush, and rotation settings are read together from the direct sink.

#### When Compare Current And Default Policy

When runtime drift from defaults should be inspected explicitly:
```moonbit
let current = sink.policy()
let defaults = sink.default_policy()
```

In this example, callers can compare current runtime settings with the initial policy snapshot.

### Error Case

e.g.:
- If callers only need one field from the policy, a narrower helper may be simpler.

- This helper describes policy state, not whether the sink is currently available.

### Notes

1. Use this helper when file policy should be handled as one object.

2. Pair it with `set_policy(...)` for roundtrip-style policy management.
