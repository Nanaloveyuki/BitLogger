---
name: file-sink-clear-rotation
group: api
category: sink
update-time: 20260613
description: Disable runtime rotation on a FileSink.
key-word:
    - file
    - sink
    - rotation
    - public
---

## File-sink-clear-rotation

Disable runtime rotation on a `FileSink`. This helper is the direct shortcut for clearing rotation policy on the concrete sink.

### Interface

```moonbit
pub fn FileSink::clear_rotation(self : FileSink) -> Unit {
```

#### input

- `self : FileSink` - File sink whose rotation policy should be cleared.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method removes the current rotation policy by setting it to `None`.
- It changes stored policy only and does not reopen the file.
- Current append and auto-flush settings are left unchanged.
- This helper is equivalent in intent to a broader setter with `None`, but is clearer at the call site.

### How to Use

Here are some specific examples provided.

#### When Need To Disable Rotation Explicitly

When direct runtime file rotation should be turned off:
```moonbit
sink.clear_rotation()
```

In this example, rotation policy is removed directly from the sink.

#### When Need A Clear Intent Shortcut

When code should make the disable-rotation intent obvious:
```moonbit
sink.clear_rotation()
ignore(sink.rotation_enabled())
```

In this example, the call site reads more clearly than using a broader policy setter.

### Error Case

e.g.:
- If callers need to switch to another rotation config rather than disable rotation, `set_rotation(...)` is the better API.

- This helper does not report past rotation failures; use `rotation_failures()` or `state()` for diagnostics.

### Notes

1. Use this helper when the desired effect is simply “rotation off”.

2. It is clearer than passing `None` through a broader setter when intent matters.
