---
name: runtime-sink-file-rotation-failures
group: api
category: runtime
update-time: 20260613
description: Read the number of rotation failures recorded by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-rotation-failures

Read the number of rotation failures recorded by a file-backed `RuntimeSink`. This helper is useful when direct runtime rotation behavior should be observed operationally.

### Interface

```moonbit
pub fn RuntimeSink::file_rotation_failures(self : RuntimeSink) -> Int {
```

#### input

- `self : RuntimeSink` - Runtime sink whose rotation-failure counter should be inspected.

#### output

- `Int` - Number of recorded rotation failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report the wrapped `FileSink` rotation-failure count.
- `QueuedFile` runtime variants forward the metric from the wrapped inner `FileSink`.
- Non-file runtime variants return `0`.
- The counter is cumulative until `file_reset_failure_counters()` clears it.

### How to Use

Here are some specific examples provided.

#### When Need Rotation-specific Diagnostics

When support output should reveal whether rotation is failing:
```moonbit
let count = sink.file_rotation_failures()
```

In this example, the runtime sink exposes a focused metric for direct rotation-path health.

#### When Validate Runtime Rotation Tuning

When changed rotation settings should be checked in operation:
```moonbit
ignore(sink.file_rotation_failures())
```

In this example, callers can observe whether runtime rotation changes introduced problems.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `0`.

- If callers need both rotation config and failure metrics, they should combine this helper with `file_rotation_config()` or `file_state()`.

### Notes

1. Use this helper when diagnosing direct runtime file rotation reliability.

2. It is especially relevant when runtime rotation policy can change after startup.
