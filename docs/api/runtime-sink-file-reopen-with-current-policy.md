---
name: runtime-sink-file-reopen-with-current-policy
group: api
category: runtime
update-time: 20260613
description: Reopen the file sink behind a RuntimeSink using its currently stored runtime policy.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-reopen-with-current-policy

Reopen the file sink behind a `RuntimeSink` using the currently stored runtime policy. This helper is useful when callers want direct recovery behavior without supplying a one-off append override.

### Interface

```moonbit
pub fn RuntimeSink::file_reopen_with_current_policy(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file sink should be reopened with current policy.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants reuse their current stored reopen policy.
- `QueuedFile` runtime variants forward reopen behavior to the wrapped inner file sink.
- This helper differs from `file_reopen(...)` because it does not accept a per-call append override.
- Non-file runtime variants return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Policy-preserving Direct Recovery

When a file sink should be reopened without changing runtime append behavior:
```moonbit
ignore(sink.file_reopen_with_current_policy())
```

In this example, recovery reuses the runtime policy already stored on the sink.

#### When Separate Recovery From Policy Mutation

When append mode should be controlled elsewhere:
```moonbit
let ok = sink.file_reopen_with_current_policy()
```

In this example, reopen is explicit while policy mutation stays separate.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers want to change append behavior during reopen, `file_reopen(...)` or `file_reopen_append()` / `file_reopen_truncate()` are better APIs.

### Notes

1. Use this helper when direct recovery should respect the currently stored runtime policy.

2. It is clearer than passing no override through a more general reopen API.
