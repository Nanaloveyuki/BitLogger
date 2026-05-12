---
name: configured-logger-file-open-failures
group: api
category: runtime
update-time: 20260512
description: Read the number of open failures recorded by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-open-failures

Read the number of open failures recorded by a `ConfiguredLogger` file sink. This helper is useful for diagnosing file-availability or reopen problems.

### Interface

```moonbit
pub fn ConfiguredLogger::file_open_failures(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose open-failure counter should be inspected.

#### output

- `Int` - Number of recorded open failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks report their recorded open-failure count.
- Queued file sinks forward the metric from the wrapped file sink.
- Non-file sinks return `0`.
- The counter is cumulative until reset.

### How to Use

Here are some specific examples provided.

#### When Need File Availability Diagnostics

When operators should see whether file open or reopen failed:
```moonbit
let count = logger.file_open_failures()
```

In this example, the configured logger exposes the open-failure metric directly.

#### When Validate Recovery Logic

When tests or support code should inspect whether reopen attempts failed:
```moonbit
ignore(logger.file_open_failures())
```

In this example, the counter helps confirm whether file-open problems occurred during runtime.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `0`.

- If callers need the full file status snapshot rather than one counter, `file_state()` is the better API.

### Notes

1. Use this helper for focused file-open diagnostics.

2. Pair it with `file_reopen(...)` and `file_available()` during recovery analysis.
