---
name: file-sink-default-policy
group: api
category: sink
update-time: 20260613
description: Read the initial default file policy captured by a FileSink.
key-word:
    - file
    - sink
    - policy
    - public
---

## File-sink-default-policy

Read the initial default file policy captured by a `FileSink`. This helper exposes the baseline file policy recorded when the sink was created.

### Interface

```moonbit
pub fn FileSink::default_policy(self : FileSink) -> FileSinkPolicy {
```

#### input

- `self : FileSink` - File sink whose default file policy should be inspected.

#### output

- `FileSinkPolicy` - Initial default file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned policy is built from the sink's stored default append, auto-flush, and rotation values.
- This helper is useful when callers need to compare runtime drift or restore defaults later.
- It is observation-only and does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Baseline Policy Visibility

When diagnostics should show the original file policy separately from the live one:
```moonbit
let defaults = sink.default_policy()
```

In this example, the direct file sink exposes its original file policy snapshot.

#### When Prepare For Policy Reset Logic

When tooling should capture or compare default settings explicitly:
```moonbit
let original = sink.default_policy()
```

In this example, callers can reason about factory policy separately from runtime changes.

### Error Case

e.g.:
- If callers only need to know whether runtime drift exists, `policy_matches_default()` is the simpler API.

- This helper does not say whether the current sink handle is available.

### Notes

1. Use this helper when the original file policy matters operationally.

2. It complements `policy()` and `reset_policy()`.
