---
name: file-sink-reopen-with-current-policy
group: api
category: sink
update-time: 20260613
description: Reopen a FileSink using its currently stored runtime policy.
key-word:
    - file
    - sink
    - reopen
    - public
---

## File-sink-reopen-with-current-policy

Reopen a `FileSink` using the currently stored runtime policy. This helper is useful when direct recovery should happen without supplying a one-off append override.

### Interface

```moonbit
pub fn FileSink::reopen_with_current_policy(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink that should be reopened with current policy.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper reuses the sink's currently stored append policy.
- It differs from `reopen(...)` because it does not accept a per-call append override.
- Existing handle state is handled through the underlying `reopen(...)` behavior.
- On failure, the sink remains unavailable and `open_failures` is updated by the reopen path.

### How to Use

Here are some specific examples provided.

#### When Need Policy-preserving Recovery

When a file sink should be reopened without changing runtime append behavior:
```moonbit
ignore(sink.reopen_with_current_policy())
```

In this example, recovery reuses the runtime policy already stored on the sink.

#### When Separate Recovery From Policy Mutation

When append mode should be controlled elsewhere:
```moonbit
let ok = sink.reopen_with_current_policy()
```

In this example, reopen is explicit while policy mutation stays separate.

### Error Case

e.g.:
- If callers want to change append behavior during reopen, `reopen(...)`, `reopen_append()`, or `reopen_truncate()` are better APIs.

- This helper still depends on the underlying file backend being able to reopen the path successfully.

### Notes

1. Use this helper when recovery should respect the currently stored runtime policy.

2. It is clearer than passing no override through a more general reopen API.
