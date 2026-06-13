---
name: runtime-sink-file-policy
group: api
category: runtime
update-time: 20260613
description: Read the current runtime file policy from a RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-policy

Read the current runtime file policy from a `RuntimeSink`. This helper exposes the active append, auto-flush, and rotation settings as one policy object.

### Interface

```moonbit
pub fn RuntimeSink::file_policy(self : RuntimeSink) -> FileSinkPolicy {
```

#### input

- `self : RuntimeSink` - Runtime sink whose current file policy should be inspected.

#### output

- `FileSinkPolicy` - Current runtime file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return the current policy from the wrapped `FileSink`.
- `QueuedFile` runtime variants forward the policy from the wrapped inner `FileSink`.
- Non-file runtime variants return the neutral fallback policy `FileSinkPolicy::new(append=false, auto_flush=false, rotation=None)`.
- This helper is broader than `file_append_mode()` or `file_auto_flush()` because it returns the whole policy object.

### How to Use

Here are some specific examples provided.

#### When Need Full Runtime Policy Visibility

When diagnostics should inspect the active file policy as one object:
```moonbit
let policy = sink.file_policy()
```

In this example, append, flush, and rotation settings are read together from the runtime sink.

#### When Compare Current And Default Policy

When runtime drift from defaults should be inspected explicitly:
```moonbit
let current = sink.file_policy()
let defaults = sink.file_default_policy()
```

In this example, callers can compare current runtime settings with the initial policy snapshot.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the return value is a neutral fallback policy rather than a real active file policy.

- If callers only need one field from the policy, a narrower helper may be simpler.

### Notes

1. Use this helper when file policy should be handled as one object.

2. Pair it with `file_set_policy(...)` for roundtrip-style policy management.
