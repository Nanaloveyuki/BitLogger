---
name: file-sink-close
group: api
category: sink
update-time: 20260613
description: Close a FileSink and drop its current file handle.
key-word:
    - file
    - sink
    - close
    - public
---

## File-sink-close

Close a `FileSink` and drop its current file handle. This helper is the direct file-sink shutdown surface when code manages a concrete `FileSink` value.

### Interface

```moonbit
pub fn FileSink::close(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink to close.

#### output

- `Bool` - Whether closing the current handle succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- If the sink currently has no file handle, the method returns `false`.
- When a handle exists, the method attempts to close it and then sets the stored handle to `None`.
- After a successful or failed close attempt on an existing handle, the sink becomes unavailable until reopened.
- This helper does not automatically reopen the sink.

### How to Use

Here are some specific examples provided.

#### When Need Direct File Teardown

When code owns a concrete file sink and wants to release its file handle explicitly:
```moonbit
ignore(sink.close())
```

In this example, the sink closes its current file handle directly.

#### When Need To Check Close Outcome Before Reopen

When code should observe whether a shutdown step succeeded:
```moonbit
let closed = sink.close()
```

In this example, the result can be used before a later `reopen(...)` step.

### Error Case

e.g.:
- If the sink is already unavailable, the method returns `false`.

- If callers only want to inspect whether the sink still has a handle, `is_available()` is the simpler API.

### Notes

1. This method changes sink availability by clearing the current handle.

2. It is commonly paired with `reopen(...)` when file lifecycle should be controlled explicitly.
