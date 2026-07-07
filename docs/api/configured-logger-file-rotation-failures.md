---
name: configured-logger-file-rotation-failures
group: api
category: runtime
update-time: 20260707
description: Read the number of rotation failures recorded by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-rotation-failures

Read the number of runtime file-rotation attempts whose critical file steps failed in a `ConfiguredLogger`.

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

- File-backed sinks report their recorded rotation-failure count through the wrapped `RuntimeSink`.
- Queued file sinks forward the metric from the wrapped inner file sink.
- Non-file sinks return `0`.
- For file-backed paths, the counter covers incomplete rotations caused by critical remove/rename/reopen failures, not every possible file-health issue.
- The counter is cumulative until reset.

### How to Use

Here are some specific examples provided.

#### When Need Rotation-specific Diagnostics

When support output should reveal whether rotation is failing:
```moonbit
let count = logger.file_rotation_failures()
```

In this example, the configured logger exposes whether runtime file rotation stopped completing its critical steps.

#### When Validate Runtime Rotation Tuning

When changed rotation settings should be checked in operation:
```moonbit
ignore(logger.file_rotation_failures())
```

In this example, callers can observe whether runtime rotation changes introduced incomplete rotations.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `0`.

- If callers need both rotation config and failure metrics, they should combine this helper with `file_rotation_config()` or `file_state()`.

- This counter does not identify the exact remove/rename/reopen step that failed.

### Notes

1. Use this helper when diagnosing incomplete file rotations.

2. It is especially relevant when runtime rotation policy can change after startup.
