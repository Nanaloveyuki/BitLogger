---
name: file-sink-path
group: api
category: sink
update-time: 20260613
description: Read the configured file path used by a FileSink.
key-word:
    - file
    - sink
    - path
    - public
---

## File-sink-path

Read the configured file path used by a `FileSink`. This helper is useful for diagnostics, support output, and confirming which concrete file destination a sink is managing.

### Interface

```moonbit
pub fn FileSink::path(self : FileSink) -> String {
```

#### input

- `self : FileSink` - File sink whose path should be inspected.

#### output

- `String` - Configured file path for the sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method returns the sink's stored file path directly.
- The path value is observation-only and does not imply current availability.
- Closing and reopening the sink do not change this stored path.
- This helper does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Direct Path Diagnostics

When diagnostics should show which file a concrete sink is managing:
```moonbit
println(sink.path())
```

In this example, operators can verify the direct file destination without reading broader runtime state.

#### When Build Support Output

When application state dumps should include the configured sink path:
```moonbit
let path = sink.path()
```

In this example, the path can be surfaced without reading policy or failure counters.

### Error Case

e.g.:
- If callers need to know whether the path is currently backed by an open handle, `is_available()` is the better API.

- This helper returns the configured path even if open or reopen attempts have failed.

### Notes

1. Use this helper for direct file-destination visibility.

2. It is a simple observation API and does not inspect wider sink health.
