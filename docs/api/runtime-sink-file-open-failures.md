---
name: runtime-sink-file-open-failures
group: api
category: runtime
update-time: 20260613
description: Read the number of open failures recorded by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-open-failures

Read the number of open failures recorded by a file-backed `RuntimeSink`. This helper is useful for direct runtime diagnostics around file availability and reopen behavior.

### Interface

```moonbit
pub fn RuntimeSink::file_open_failures(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose open-failure counter should be inspected.

#### output

- `Int` - Number of recorded open failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report the wrapped `FileSink` open-failure count.
- `QueuedFile` runtime variants forward the metric from the wrapped inner `FileSink`.
- Non-file runtime variants return `0`.
- The counter is cumulative until `file_reset_failure_counters()` clears it.

### How to Use

Here are some specific examples provided.

#### When Need File Availability Diagnostics

When direct runtime support output should show whether file open or reopen failed:
```moonbit
let count = sink.file_open_failures()
```

In this example, the runtime sink exposes the open-failure metric directly.

#### When Validate Recovery Logic

When recovery code should inspect whether reopen attempts failed:
```moonbit
ignore(sink.file_open_failures())
```

In this example, the counter helps confirm whether file-open problems occurred during runtime.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `0`.

- If callers need the full file status snapshot rather than one counter, `file_state()` is the better API.

### Notes

1. Use this helper for focused direct runtime file-open diagnostics.

2. Pair it with `file_reopen(...)` and `file_available()` during recovery analysis.
