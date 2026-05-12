---
name: configured-logger-file-rotation-failures
group: api
category: runtime
update-time: 20260512
description: Read the number of rotation failures recorded by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-rotation-failures

Read the number of rotation failures recorded by a `ConfiguredLogger` file sink. This helper is useful when runtime rotation behavior should be observed operationally.

### Interface

```moonbit
pub fn ConfiguredLogger::file_rotation_failures(self : ConfiguredLogger) -> Int {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose rotation-failure counter should be inspected.

#### output

- `Int` - Number of recorded rotation failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks report their recorded rotation-failure count.
- Queued file sinks forward the metric from the wrapped file sink.
- Non-file sinks return `0`.
- The counter is cumulative until reset.

### How to Use

Here are some specific examples provided.

#### When Need Rotation-specific Diagnostics

When support output should reveal whether rotation is failing:
```moonbit
let count = logger.file_rotation_failures()
```

In this example, the configured logger exposes a focused metric for rotation-path health.

#### When Validate Runtime Rotation Tuning

When changed rotation settings should be checked in operation:
```moonbit
ignore(logger.file_rotation_failures())
```

In this example, callers can observe whether runtime rotation changes introduced problems.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `0`.

- If callers need both rotation config and failure metrics, they should combine this helper with `file_rotation_config()` or `file_state()`.

### Notes

1. Use this helper when diagnosing file rotation reliability.

2. It is especially relevant when runtime rotation policy can change after startup.
