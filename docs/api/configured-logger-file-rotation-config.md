---
name: configured-logger-file-rotation-config
group: api
category: runtime
update-time: 20260512
description: Read the current rotation configuration used by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-rotation-config

Read the current rotation configuration used by a `ConfiguredLogger` file sink. This helper exposes the active runtime rotation parameters when rotation is enabled.

### Interface

```moonbit
pub fn ConfiguredLogger::file_rotation_config(self : ConfiguredLogger) -> FileRotation? {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose rotation config should be inspected.

#### output

- `FileRotation?` - Current rotation config, or `None` if rotation is disabled or the sink is not file-backed.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return their current rotation configuration when enabled through the wrapped `RuntimeSink`.
- Queued file sinks forward the config from the wrapped inner file sink.
- Non-file sinks return `None`.
- This helper is useful when callers need active runtime rotation parameters rather than only a boolean flag.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Rotation Parameters

When support output should include the active rotation policy:
```moonbit
let rotation = logger.file_rotation_config()
```

In this example, the configured logger exposes live runtime rotation parameters directly.

#### When Branch On Optional Rotation Presence

When code should react differently for rotating file sinks:
```moonbit
match logger.file_rotation_config() {
  Some(cfg) => ignore(cfg)
  None => ()
}
```

In this example, optional return shape reflects whether rotation is active.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `None`.

- If callers only need to know whether rotation is enabled, `file_rotation_enabled()` is the simpler API.

### Notes

1. Use this helper when current runtime rotation parameters matter.

2. It is useful after policy updates or recovery flows.
