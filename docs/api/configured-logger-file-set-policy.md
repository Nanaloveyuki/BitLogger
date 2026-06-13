---
name: configured-logger-file-set-policy
group: api
category: runtime
update-time: 20260512
description: Apply a bundled runtime file policy update to a configured file-backed logger.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-set-policy

Apply a bundled runtime file policy update to a `ConfiguredLogger`. This helper updates append mode, auto-flush, and rotation together through one runtime policy object.

### Interface

```moonbit
pub fn ConfiguredLogger::file_set_policy(self : ConfiguredLogger, policy : FileSinkPolicy) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file policy should change.
- `policy : FileSinkPolicy` - Bundled runtime file policy to apply.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks update append, auto-flush, and rotation together through the wrapped `RuntimeSink`.
- Queued file sinks forward the policy update to the wrapped inner file sink.
- Non-file sinks return `false`.
- This helper is broader than the single-setting setters because it updates the whole file policy in one call.

### How to Use

Here are some specific examples provided.

#### When Need Bundled Runtime Policy Changes

When append, flush, and rotation should change together:
```moonbit
ignore(logger.file_set_policy(FileSinkPolicy::new(
  append=true,
  auto_flush=false,
  rotation=Some(file_rotation(2048, max_backups=2)),
)))
```

In this example, runtime file behavior is updated as one policy change.

#### When Apply A Policy Snapshot

When a previously captured or computed policy should be restored:
```moonbit
let ok = logger.file_set_policy(policy)
```

In this example, callers can reapply a whole policy object without splitting it into separate setter calls.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers only need to change one setting, a narrower setter such as `file_set_auto_flush(...)` or `file_set_rotation(...)` may be clearer.

### Notes

1. Use this helper when the runtime policy should be treated as one cohesive object.

2. It pairs naturally with `file_policy()` and `file_default_policy()`.
