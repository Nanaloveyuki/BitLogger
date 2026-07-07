---
name: runtime-sink-file-set-policy
group: api
category: runtime
update-time: 20260707
description: Apply a bundled runtime file policy update to a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-set-policy

Apply a bundled runtime file policy update to a `RuntimeSink`. This helper updates append mode, auto-flush, and rotation together through one runtime policy object on direct sink values.

The input `FileSinkPolicy` value is owned by `src/file_model`; this method belongs to the runtime facade layer and forwards policy mutation through `src/runtime` to file-backed variants that ultimately use `src/file_runtime.FileSink`.

### Interface

```moonbit
pub fn RuntimeSink::file_set_policy(self : RuntimeSink, policy : FileSinkPolicy) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file policy should change.
- `policy : FileSinkPolicy` - Bundled runtime file policy to apply.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants update append, auto-flush, and rotation together on the wrapped `FileSink` and return `true`.
- `QueuedFile` runtime variants forward the policy update to the wrapped inner `FileSink` only when no queued records are pending.
- The accepted policy object itself is the shared `@file_model.FileSinkPolicy` model, not a runtime-owned concrete type.
- Non-file runtime variants return `false`.
- This helper is broader than the single-setting setters because it updates the whole file policy in one call.
- If a queued file sink still has pending records, the update is rejected and returns `false` so already queued records are not later written under a different policy bundle than the one they were queued under.

### How to Use

Here are some specific examples provided.

#### When Need Bundled Runtime Policy Changes

When append, flush, and rotation should change together:
```moonbit
ignore(sink.file_set_policy(FileSinkPolicy::new(
  append=true,
  auto_flush=false,
  rotation=Some(file_rotation(2048, max_backups=2)),
)))
```

In this example, runtime file behavior is updated as one policy change.

#### When Apply A Policy Snapshot

When a previously captured or computed policy should be restored:
```moonbit
let ok = sink.file_set_policy(policy)
```

In this example, callers can reapply a whole policy object without splitting it into separate setter calls.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers only need to change one setting, a narrower setter such as `file_set_auto_flush(...)` or `file_set_rotation(...)` may be clearer.

- If a queued file sink still has pending records, callers should flush or close it first before changing policy.

### Notes

1. Use this helper when the runtime policy should be treated as one cohesive object.

2. On queued file sinks, clear pending records first so policy mutation does not retroactively affect already queued writes.
