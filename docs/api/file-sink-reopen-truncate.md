---
name: file-sink-reopen-truncate
group: api
category: sink
update-time: 20260613
description: Reopen a FileSink in truncate mode.
key-word:
    - file
    - sink
    - reopen
    - public
---

## File-sink-reopen-truncate

Reopen a `FileSink` in truncate mode. This helper is the explicit truncate-oriented recovery or reset shortcut on the direct sink.

### Interface

```moonbit
pub fn FileSink::reopen_truncate(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink that should be reopened in truncate mode.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper is a specialized shortcut over `reopen(append=Some(false))`.
- Reopen behavior is fixed to truncate mode.
- The stored append policy is updated to `false` as part of the reopen path.
- On failure, the sink remains unavailable and `open_failures` is incremented.

### How to Use

Here are some specific examples provided.

#### When Need A Fresh Output File

When a direct runtime file should be reopened from an empty state:
```moonbit
ignore(sink.reopen_truncate())
```

In this example, reopen behavior truncates the file before future writes continue.

#### When Want An Explicit Truncate Shortcut

When code should make destructive reopen intent obvious:
```moonbit
let ok = sink.reopen_truncate()
```

In this example, the call site expresses reset-style reopen behavior directly.

### Error Case

e.g.:
- If callers want to preserve existing file content, `reopen_append()` is the correct API.

- If reopen fails, the helper returns `false` and the sink stays unavailable.

### Notes

1. Use this helper when starting from a fresh file is intentional.

2. Truncate-mode reopen is a stronger action than generic reopen recovery.
