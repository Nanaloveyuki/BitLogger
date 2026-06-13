---
name: file-sink-rotation-config
group: api
category: sink
update-time: 20260613
description: Read the current optional rotation configuration from a FileSink.
key-word:
    - file
    - sink
    - rotation
    - public
---

## File-sink-rotation-config

Read the current optional rotation configuration from a `FileSink`. This helper exposes the active direct runtime rotation parameters when rotation is configured.

### Interface

```moonbit
pub fn FileSink::rotation_config(self : FileSink) -> FileRotation? {
```

#### input

- `self : FileSink` - File sink whose current rotation config should be inspected.

#### output

- `FileRotation?` - Current rotation config, or `None` if rotation is disabled.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method returns the sink's current optional `FileRotation` value directly.
- It is more detailed than `rotation_enabled()` because it exposes the actual runtime rotation parameters.
- A `None` result means the sink currently has no rotation policy.
- This helper observes current policy state only and does not mutate the sink.

### How to Use

Here are some specific examples provided.

#### When Need Active Rotation Parameters

When support output or runtime checks should show the current direct rotation policy:
```moonbit
let rotation = sink.rotation_config()
```

In this example, callers can inspect the current optional rotation config on the concrete sink.

#### When Branch On Optional Rotation Presence

When code should behave differently for rotating and non-rotating file sinks:
```moonbit
match sink.rotation_config() {
  Some(cfg) => ignore(cfg)
  None => ()
}
```

In this example, the optional return shape reflects whether runtime rotation is configured.

### Error Case

e.g.:
- If callers only need a boolean answer, `rotation_enabled()` is the simpler API.

- This helper does not report whether a past rotation succeeded; use `rotation_failures()` or `state()` for diagnostics.

### Notes

1. Use this helper when current runtime rotation parameters matter.

2. It pairs naturally with `set_rotation(...)`, `clear_rotation()`, and `set_policy(...)`.
