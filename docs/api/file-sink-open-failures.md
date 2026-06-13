---
name: file-sink-open-failures
group: api
category: sink
update-time: 20260613
description: Read the number of open failures recorded by a FileSink.
key-word:
    - file
    - sink
    - open
    - public
---

## File-sink-open-failures

Read the number of open failures recorded by a `FileSink`. This helper is useful for diagnosing direct file-availability or reopen problems.

### Interface

```moonbit
pub fn FileSink::open_failures(self : FileSink) -> Int {
```

#### input

- `self : FileSink` - File sink whose open-failure counter should be inspected.

#### output

- `Int` - Number of recorded open failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- The sink reports its recorded open-failure count directly.
- The counter is cumulative until reset.
- This helper is observation-only and does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need File Availability Diagnostics

When operators should see whether file open or reopen failed:
```moonbit
let count = sink.open_failures()
```

In this example, the direct sink exposes the open-failure metric directly.

#### When Validate Recovery Logic

When tests or support code should inspect whether reopen attempts failed:
```moonbit
ignore(sink.open_failures())
```

In this example, the counter helps confirm whether file-open problems occurred during runtime.

### Error Case

e.g.:
- If callers need the full file status snapshot rather than one counter, `state()` is the better API.

- This counter does not tell you which particular reopen attempt failed.

### Notes

1. Use this helper for focused direct file-open diagnostics.

2. Pair it with `reopen(...)` and `is_available()` during recovery analysis.
