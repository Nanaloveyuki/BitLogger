---
name: runtime-sink-file-reopen-append
group: api
category: runtime
update-time: 20260613
description: Reopen the file sink behind a RuntimeSink in append mode.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-reopen-append

Reopen the file sink behind a `RuntimeSink` in append mode. This helper is the explicit append-oriented direct recovery shortcut.

### Interface

```moonbit
pub fn RuntimeSink::file_reopen_append(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file sink should be reopened in append mode.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants reopen in append mode.
- `QueuedFile` runtime variants forward reopen behavior to the wrapped inner file sink.
- This helper is a specialized shortcut for a common reopen mode.
- Non-file runtime variants return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Append-preserving Direct Recovery

When file logging should continue appending after a reopen:
```moonbit
ignore(sink.file_reopen_append())
```

In this example, reopen behavior is fixed to append mode.

#### When Want An Explicit Append Shortcut

When code should avoid manually setting append overrides:
```moonbit
let ok = sink.file_reopen_append()
```

In this example, the call site states append intent directly.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need truncate behavior instead, `file_reopen_truncate()` is the correct API.

### Notes

1. Use this helper for explicit append-mode reopen flows on direct `RuntimeSink` values.

2. It is especially useful after transient file availability issues.
