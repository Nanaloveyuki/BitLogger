---
name: file-sink-reopen
group: api
category: sink
update-time: 20260613
description: Reopen a FileSink with an optional append-mode override.
key-word:
    - file
    - sink
    - reopen
    - public
---

## File-sink-reopen

Reopen a `FileSink`. This helper is useful for direct recovery flows after file unavailability or after file policy changes.

### Interface

```moonbit
pub fn FileSink::reopen(self : FileSink, append~ : Bool? = None) -> Bool {
```

#### input

- `self : FileSink` - File sink that should be reopened.
- `append : Bool?` - Optional append-mode override used for reopen behavior.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- `append=None` preserves the sink's current append policy.
- `Some(true/false)` overrides append mode for this reopen and updates the stored append policy.
- If a handle is currently open, the method closes it before attempting reopen.
- On reopen failure, `open_failures` is incremented and the sink remains unavailable.

### How to Use

Here are some specific examples provided.

#### When Need Recovery After File Failure

When direct file logging code should attempt to restore sink availability:
```moonbit
ignore(sink.reopen())
```

In this example, the sink tries to reopen using its current append policy.

#### When Need Explicit Append-mode Reopen

When recovery should choose append or truncate behavior explicitly:
```moonbit
let ok = sink.reopen(append=Some(true))
```

In this example, reopen behavior is directed by the call site.

### Error Case

e.g.:
- If reopen fails, the method returns `false` and increments `open_failures()`.

- If callers only need the current configured policy with no one-off override, `reopen_with_current_policy()` may be the clearer API.

### Notes

1. Use this helper for direct recovery flows.

2. Pair it with `is_available()` and failure counters when diagnosing reopen behavior.
