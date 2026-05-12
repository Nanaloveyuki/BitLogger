---
name: configured-logger-file-write-failures
group: api
category: runtime
update-time: 20260512
description: Read the number of write failures recorded by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-write-failures

Read the number of write failures recorded by a `ConfiguredLogger` file sink. This helper is useful for diagnosing runtime write-path problems.

### Interface

```moonbit
pub fn ConfiguredLogger::file_write_failures(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose write-failure counter should be inspected.

#### output

- `Int` - Number of recorded write failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks report their recorded write-failure count.
- Queued file sinks forward the metric from the wrapped file sink.
- Non-file sinks return `0`.
- The counter is cumulative until reset.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Write-path Diagnostics

When support output should show whether writes have been failing:
```moonbit
let count = logger.file_write_failures()
```

In this example, callers get a focused signal for file write-path health.

#### When Compare Sink Health After Recovery

When recovery logic should verify whether new failures still occur:
```moonbit
ignore(logger.file_write_failures())
```

In this example, the metric helps measure whether runtime writes improved after intervention.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `0`.

- If callers need a fuller view of file health, `file_state()` or `file_runtime_state()` may be better APIs.

### Notes

1. Use this helper for focused write-failure visibility.

2. Pair it with `file_flush_failures()` when diagnosing output-path instability.
