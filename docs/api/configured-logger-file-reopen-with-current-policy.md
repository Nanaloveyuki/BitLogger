---
name: configured-logger-file-reopen-with-current-policy
group: api
category: runtime
update-time: 20260512
description: Reopen the file sink behind a configured runtime logger using its currently stored runtime policy.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-reopen-with-current-policy

Reopen the file sink behind a `ConfiguredLogger` using the currently stored runtime policy. This helper is useful when callers want recovery behavior without supplying a one-off append override.

### Interface

```moonbit
pub fn ConfiguredLogger::file_reopen_with_current_policy(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file sink should be reopened with current policy.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain file sinks reuse their current stored reopen policy through the wrapped `RuntimeSink`.
- Queued file sinks forward reopen behavior to the wrapped inner file sink.
- This helper differs from `file_reopen(...)` because it does not accept a per-call append override.
- Non-file sinks return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Policy-preserving Recovery

When a file sink should be reopened without changing runtime append behavior:
```moonbit
ignore(logger.file_reopen_with_current_policy())
```

In this example, recovery reuses the runtime policy already stored on the sink.

#### When Separate Recovery From Policy Mutation

When append mode should be controlled elsewhere:
```moonbit
let ok = logger.file_reopen_with_current_policy()
```

In this example, reopen is explicit while policy mutation stays separate.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers want to change append behavior during reopen, `file_reopen(...)` or `file_reopen_append()` / `file_reopen_truncate()` are better APIs.

### Notes

1. Use this helper when recovery should respect the currently stored runtime policy.

2. It is clearer than passing no override through a more general reopen API.
