---
name: file-sink-rotation-failures
group: api
category: sink
update-time: 20260613
description: Read the number of rotation failures recorded by a FileSink.
key-word:
    - file
    - sink
    - rotation
    - public
---

## File-sink-rotation-failures

Read the number of rotation failures recorded by a `FileSink`. This helper is useful when direct runtime rotation behavior should be observed operationally.

### Interface

```moonbit
pub fn FileSink::rotation_failures(self : FileSink) -> Int {
```

#### input

- `self : FileSink` - File sink whose rotation-failure counter should be inspected.

#### output

- `Int` - Number of recorded rotation failures.

### Explanation

Detailed rules explaining key parameters and behaviors

- The sink reports its recorded rotation-failure count directly.
- The counter is cumulative until reset.
- This helper is observation-only and does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Rotation-specific Diagnostics

When support output should reveal whether direct sink rotation is failing:
```moonbit
let count = sink.rotation_failures()
```

In this example, the concrete file sink exposes a focused metric for rotation-path health.

#### When Validate Runtime Rotation Tuning

When changed rotation settings should be checked in operation:
```moonbit
ignore(sink.rotation_failures())
```

In this example, callers can observe whether runtime rotation changes introduced problems.

### Error Case

e.g.:
- If callers need both rotation config and failure metrics, they should combine this helper with `rotation_config()` or `state()`.

- This counter alone does not say whether the sink is currently available.

### Notes

1. Use this helper when diagnosing direct file rotation reliability.

2. It is especially relevant when runtime rotation policy can change after startup.
