---
name: runtime-sink-file-reopen
group: api
category: runtime
update-time: 20260707
description: Reopen the file sink behind a RuntimeSink with an optional append-mode override.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-reopen

Reopen the file sink behind a `RuntimeSink`. This helper is useful for direct recovery flows after file unavailability or policy changes.

### Interface

```moonbit
pub fn RuntimeSink::file_reopen(self : RuntimeSink, append~ : Bool? = None) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file sink should be reopened.
- `append : Bool?` - Optional append-mode override used for reopen behavior.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants reopen directly.
- `QueuedFile` runtime variants forward reopen behavior to the wrapped inner file sink only when no queued records are pending.
- `append=None` preserves current reopen policy, while `Some(true/false)` overrides append mode.
- Non-file runtime variants return `false`.
- If a queued file sink still has pending records, reopen is rejected and returns `false` so queued records are not later written under a different reopen mode than the one they were queued under.

### How to Use

Here are some specific examples provided.

#### When Need Recovery After File Failure

When code should attempt to restore file logging through a `RuntimeSink` value:
```moonbit
ignore(sink.file_reopen())
```

In this example, the runtime sink tries to reopen its file sink using current policy.

#### When Need Explicit Append-mode Reopen

When recovery should choose append or truncate behavior explicitly:
```moonbit
let ok = sink.file_reopen(append=Some(true))
```

In this example, reopen behavior is directed by the call site.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers only need the current configured policy, `file_reopen_with_current_policy()` may be the clearer API.

- If a queued file sink still has pending records, callers should flush or close it first before attempting reopen.

### Notes

1. Use this helper for explicit direct recovery flows on `RuntimeSink` values.

2. On queued file sinks, clear pending records first so reopen semantics stay stable for already queued writes.
