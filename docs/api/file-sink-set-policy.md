---
name: file-sink-set-policy
group: api
category: sink
update-time: 20260613
description: Apply a bundled runtime file policy update to a FileSink.
key-word:
    - file
    - sink
    - policy
    - public
---

## File-sink-set-policy

Apply a bundled runtime file policy update to a `FileSink`. This helper updates append mode, auto-flush, and rotation together through one policy object on the concrete sink.

### Interface

```moonbit
pub fn FileSink::set_policy(self : FileSink, policy : FileSinkPolicy) -> Unit {
```

#### input

- `self : FileSink` - File sink whose runtime file policy should change.
- `policy : FileSinkPolicy` - Bundled runtime file policy to apply.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method copies `policy.append`, `policy.auto_flush`, and `policy.rotation` onto the sink.
- It updates the whole runtime file policy in one call instead of changing each field separately.
- It does not reopen the sink, rotate immediately, or report success with a return value.
- It is broader than `set_append_mode(...)`, `set_auto_flush(...)`, or `set_rotation(...)` because it applies all policy fields together.

### How to Use

Here are some specific examples provided.

#### When Need Bundled Runtime Policy Changes

When append, flush, and rotation should change together on a direct file sink:
```moonbit
sink.set_policy(FileSinkPolicy::new(
  append=true,
  auto_flush=false,
  rotation=Some(file_rotation(2048, max_backups=2)),
))
```

In this example, runtime file behavior is updated as one cohesive policy change.

#### When Restore A Policy Snapshot

When a previously captured or computed policy should be reapplied:
```moonbit
sink.set_policy(policy)
```

In this example, callers can restore a whole policy object without splitting it into separate setter calls.

### Error Case

e.g.:
- If callers only need to change one field, a narrower setter may be clearer.

- This helper does not report past open, write, flush, or rotation failures; inspect the failure counters or `state()` separately when diagnostics matter.

### Notes

1. Use this helper when runtime file policy should be treated as one cohesive object.

2. It pairs naturally with `policy()` and `default_policy()`.
