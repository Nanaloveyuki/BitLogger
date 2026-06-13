---
name: runtime-sink-file-set-rotation
group: api
category: runtime
update-time: 20260613
description: Update the rotation configuration used by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-set-rotation

Update the rotation configuration used by a file-backed `RuntimeSink`. This helper changes direct runtime file rotation behavior without rebuilding or rewrapping the sink.

### Interface

```moonbit
pub fn RuntimeSink::file_set_rotation(self : RuntimeSink, rotation : FileRotation?) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose rotation policy should change.
- `rotation : FileRotation?` - New rotation config, or `None` to disable rotation.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants update the wrapped `FileSink` rotation policy and return `true`.
- `QueuedFile` runtime variants forward the update to the wrapped inner `FileSink` and return `true`.
- Passing `None` disables rotation.
- Non-file runtime variants return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Rotation Tuning

When a file-backed runtime sink should enable or change rotation dynamically:
```moonbit
ignore(sink.file_set_rotation(Some(file_rotation(1024, max_backups=3))))
```

In this example, runtime rotation behavior is updated without rebuilding the sink.

#### When Need To Disable Rotation Through The Setter

When the file sink should stop rotating through one general update path:
```moonbit
let ok = sink.file_set_rotation(None)
```

In this example, the direct runtime file sink has its rotation policy cleared explicitly.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers only want to remove rotation, `file_clear_rotation()` is the more direct API.

### Notes

1. Use this helper when setting a full direct runtime rotation config.

2. It is useful for operational tuning without rebuilding the sink.
