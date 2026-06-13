---
name: runtime-sink-file-clear-rotation
group: api
category: runtime
update-time: 20260613
description: Disable runtime rotation on a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-clear-rotation

Disable runtime rotation on a file-backed `RuntimeSink`. This helper is the direct shortcut for clearing rotation policy from a runtime sink value.

### Interface

```moonbit
pub fn RuntimeSink::file_clear_rotation(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose rotation policy should be cleared.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants clear rotation on the wrapped `FileSink` and return `true`.
- `QueuedFile` runtime variants forward the update to the wrapped inner `FileSink` and return `true`.
- Non-file runtime variants return `false`.
- This helper is equivalent in intent to setting rotation to `None`, but is clearer at the call site.

### How to Use

Here are some specific examples provided.

#### When Need To Disable Rotation Explicitly

When runtime file rotation should be turned off on a direct sink value:
```moonbit
ignore(sink.file_clear_rotation())
```

In this example, rotation policy is removed directly.

#### When Need A Clear Intent Shortcut

When code should make the disable-rotation intent obvious:
```moonbit
let ok = sink.file_clear_rotation()
```

In this example, the call site reads more clearly than a generic config setter.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need to switch to another rotation config rather than disable rotation, `file_set_rotation(...)` is the better API.

### Notes

1. Use this helper when the desired effect is simply `rotation off`.

2. It is clearer than passing `None` through a broader setter when intent matters.
