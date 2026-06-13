---
name: runtime-sink-file-reopen-truncate
group: api
category: runtime
update-time: 20260613
description: Reopen the file sink behind a RuntimeSink in truncate mode.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-reopen-truncate

Reopen the file sink behind a `RuntimeSink` in truncate mode. This helper is the explicit truncate-oriented direct recovery or reset shortcut.

### Interface

```moonbit
pub fn RuntimeSink::file_reopen_truncate(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file sink should be reopened in truncate mode.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants reopen in truncate mode.
- `QueuedFile` runtime variants forward reopen behavior to the wrapped inner file sink.
- This helper is a specialized shortcut for a common reset-style reopen mode.
- Non-file runtime variants return `false`.

### How to Use

Here are some specific examples provided.

#### When Need A Fresh Output File

When a runtime file should be reopened from an empty state:
```moonbit
ignore(sink.file_reopen_truncate())
```

In this example, reopen behavior truncates the file before future writes continue.

#### When Want An Explicit Truncate Shortcut

When code should make destructive reopen intent obvious:
```moonbit
let ok = sink.file_reopen_truncate()
```

In this example, the call site expresses reset-style reopen behavior directly.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers want to preserve existing file content, `file_reopen_append()` is the correct API.

### Notes

1. Use this helper when starting from a fresh file is intentional.

2. Truncate-mode reopen is a stronger action than generic reopen recovery.
