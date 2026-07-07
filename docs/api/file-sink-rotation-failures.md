---
name: file-sink-rotation-failures
group: api
category: sink
update-time: 20260707
description: Read the number of rotation failures recorded by a FileSink.
key-word:
    - file
    - sink
    - rotation
    - public
---

## File-sink-rotation-failures

Read the number of rotation attempts whose critical file-rotation steps failed for a `FileSink`.

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
- The counter increases when a rotation attempt cannot complete its critical file steps, such as removing the active file with zero backups, renaming a live file into `.1`, shifting an existing backup to a higher slot, or reopening the fresh active file afterward.
- Missing optional backup slots do not count by themselves; only steps that fail while their source path still exists are treated as rotation failures.
- The counter is cumulative until reset.
- This helper is observation-only and does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Rotation-specific Diagnostics

When support output should reveal whether direct sink rotation is failing:
```moonbit
let count = sink.rotation_failures()
```

In this example, the concrete file sink exposes whether a rotation attempt hit a critical file-step failure.

#### When Validate Runtime Rotation Tuning

When changed rotation settings should be checked in operation:
```moonbit
ignore(sink.rotation_failures())
```

In this example, callers can observe whether runtime rotation changes started producing incomplete rotations.

### Error Case

e.g.:
- If callers need both rotation config and failure metrics, they should combine this helper with `rotation_config()` or `state()`.

- This counter alone does not identify which rename/remove/reopen step failed.

- This counter alone does not say whether the sink is currently available.

### Notes

1. Use this helper when diagnosing incomplete direct file rotations.

2. It is especially relevant when runtime rotation policy can change after startup.
