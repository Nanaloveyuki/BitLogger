---
name: file-sink-reopen-append
group: api
category: sink
update-time: 20260717
description: Reopen a FileSink in append mode.
key-word:
    - file
    - sink
    - reopen
    - public
---

## File-sink-reopen-append

Reopen a `FileSink` in append mode. This helper is the explicit append-oriented recovery shortcut on the direct sink.

### Interface

```moonbit
pub fn FileSink::reopen_append(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink that should be reopened in append mode.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper is a specialized shortcut over `reopen(append=Some(true))`.
- Reopen behavior is fixed to append mode.
- The stored append policy is updated to `true` as part of the reopen path.
- On failure, the sink remains unavailable and `open_failures` is incremented.
- After a rotation failure, this is the explicit recovery path once the underlying remove, rename, or open condition has been resolved.

### How to Use

Here are some specific examples provided.

#### When Need Append-preserving Recovery

When file logging should continue appending after a reopen:
```moonbit
ignore(sink.reopen_append())
```

In this example, reopen behavior is fixed to append mode.

#### When Want An Explicit Append Shortcut

When code should avoid manually setting append overrides:
```moonbit
let ok = sink.reopen_append()
```

In this example, the call site states append intent directly.

### Error Case

e.g.:
- If callers need truncate behavior instead, `reopen_truncate()` is the correct API.

- If reopen fails, the helper returns `false` and the sink stays unavailable.

### Notes

1. Use this helper for explicit append-mode reopen flows.

2. It is especially useful after transient file availability issues.
