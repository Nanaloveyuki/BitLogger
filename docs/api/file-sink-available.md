---
name: file-sink-available
group: api
category: sink
update-time: 20260613
description: Read whether a FileSink currently has an available underlying file handle.
key-word:
    - file
    - sink
    - available
    - public
---

## File-sink-available

Read whether a `FileSink` currently has an available underlying file handle. This helper is useful for runtime diagnostics and for deciding whether reopen or fallback behavior is needed.

### Interface

```moonbit
pub fn FileSink::is_available(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink whose current availability should be inspected.

#### output

- `Bool` - Whether the sink currently holds an active file handle.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method reports whether `self.handle` is currently `Some(_)`.
- A sink can become unavailable after open failure or after an explicit `close()`.
- This helper does not mutate sink state.
- It is the direct `FileSink` counterpart to configured-logger file availability checks.

### How to Use

Here are some specific examples provided.

#### When Need Direct Sink Health Checks

When code works with a concrete file sink and should verify handle readiness:
```moonbit
if !sink.is_available() {
  println("file sink unavailable")
}
```

In this example, the caller can detect whether the sink currently has an active file handle.

#### When Gate Recovery Or Reopen Logic

When a reopen step should only run after loss of availability:
```moonbit
let ok = sink.is_available()
```

In this example, the boolean result can drive later recovery behavior.

### Error Case

e.g.:
- If the sink failed to open initially, this method returns `false`.

- If callers need failure counters or a richer state snapshot rather than a yes-or-no result, `state()` is the better API.

### Notes

1. Use this helper for lightweight file sink health checks.

2. Pair it with `reopen(...)`, `state()`, or failure-counter APIs when diagnosing file sink problems.
