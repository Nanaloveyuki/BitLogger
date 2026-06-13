---
name: file-sink-rotation-enabled
group: api
category: sink
update-time: 20260613
description: Read whether a FileSink currently has rotation configured.
key-word:
    - file
    - sink
    - rotation
    - public
---

## File-sink-rotation-enabled

Read whether a `FileSink` currently has rotation configured. This helper is the quickest direct check for whether size-based file rotation is active on the sink.

### Interface

```moonbit
pub fn FileSink::rotation_enabled(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink whose current rotation setting should be inspected.

#### output

- `Bool` - Whether the sink currently has a `Some(FileRotation)` policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method reports whether `self.rotation` is currently set.
- It is a lightweight boolean companion to `rotation_config()`.
- The result describes current policy state, not whether a rotation just happened successfully.
- This helper does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need A Simple Rotation-policy Check

When diagnostics should show whether direct file rotation is enabled:
```moonbit
let enabled = sink.rotation_enabled()
```

In this example, callers can branch on whether rotation policy is currently present.

#### When Validate Rotation Policy Changes

When code should confirm that a policy update took effect:
```moonbit
sink.set_rotation(Some(file_rotation(1024, max_backups=3)))
ignore(sink.rotation_enabled())
```

In this example, the boolean result reflects whether the sink now carries rotation config.

### Error Case

e.g.:
- If callers need the actual `FileRotation` value, `rotation_config()` is the better API.

- This helper does not report past rotation failures; use `rotation_failures()` or `state()` for that.

### Notes

1. Use this helper for quick rotation-policy visibility.

2. It is a lighter-weight companion to reading the full rotation config.
