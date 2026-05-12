---
name: configured-logger-file-flush-failures
group: api
category: runtime
update-time: 20260512
description: Read the number of flush failures recorded by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-flush-failures

Read the number of flush failures recorded by a `ConfiguredLogger` file sink. This helper is useful for diagnosing durability-path problems on file-backed loggers.

### Interface

```moonbit
pub fn ConfiguredLogger::file_flush_failures(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose flush-failure counter should be inspected.

#### output

- `Int` - Number of recorded flush failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks report their recorded flush-failure count.
- Queued file sinks forward the metric from the wrapped file sink.
- Non-file sinks return `0`.
- The counter is cumulative until reset.

### How to Use

Here are some specific examples provided.

#### When Need Durability-path Diagnostics

When support output should show flush-path instability:
```moonbit
let count = logger.file_flush_failures()
```

In this example, the configured logger exposes whether flush attempts have been failing.

#### When Inspect Effects Of Auto-flush Policy

When runtime durability tuning should be inspected operationally:
```moonbit
ignore(logger.file_flush_failures())
```

In this example, callers can correlate flush failures with runtime file policy choices.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `0`.

- If callers need current policy and counters together, `file_state()` is the better API.

### Notes

1. Use this helper when flush-path reliability matters.

2. Pair it with `file_auto_flush()` and `file_flush()` when diagnosing durability behavior.
