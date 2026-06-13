---
name: runtime-sink-file-default-policy
group: api
category: runtime
update-time: 20260613
description: Read the initial default file policy associated with a RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-default-policy

Read the initial default file policy associated with a `RuntimeSink`. This helper exposes the baseline file policy captured when the runtime sink was created.

### Interface

```moonbit
pub fn RuntimeSink::file_default_policy(self : RuntimeSink) -> FileSinkPolicy {
```

#### input

- `self : RuntimeSink` - Runtime sink whose default file policy should be inspected.

#### output

- `FileSinkPolicy` - Initial default file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return the default policy captured at creation time.
- `QueuedFile` runtime variants forward the default policy from the wrapped inner `FileSink`.
- Non-file runtime variants return the neutral fallback policy `FileSinkPolicy::new(append=false, auto_flush=false, rotation=None)`.
- This helper is useful when callers need to compare runtime drift or restore defaults later.

### How to Use

Here are some specific examples provided.

#### When Need Baseline Policy Visibility

When diagnostics should show the original file policy separately from the live one:
```moonbit
let defaults = sink.file_default_policy()
```

In this example, the runtime sink exposes its original file policy snapshot.

#### When Prepare For Policy Reset Logic

When tooling should capture or compare default settings explicitly:
```moonbit
let original = sink.file_default_policy()
```

In this example, callers can reason about factory file policy separately from runtime changes.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the return value is a neutral fallback policy.

- If callers only need to know whether runtime drift exists, `file_policy_matches_default()` is the simpler API.

### Notes

1. Use this helper when the original file policy matters operationally.

2. It complements `file_policy()` and `file_reset_policy()`.
