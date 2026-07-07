---
name: runtime-sink-file-rotation-config
group: api
category: runtime
update-time: 20260613
description: Read the current rotation configuration used by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-rotation-config

Read the current rotation configuration used by a file-backed `RuntimeSink`. This helper exposes active direct runtime rotation parameters when rotation is enabled.

The returned `FileRotation` value is owned by `src/file_model`; this method belongs to the runtime facade layer and reads rotation policy through `src/runtime` over file-backed variants that ultimately use `src/file_runtime.FileSink`.

### Interface

```moonbit
pub fn RuntimeSink::file_rotation_config(self : RuntimeSink) -> FileRotation? {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file rotation config should be inspected.

#### output

- `FileRotation?` - Current rotation config, or `None` if rotation is disabled or the sink is not file-backed.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants return the current rotation config from the wrapped `FileSink`.
- `QueuedFile` runtime variants forward the config from the wrapped inner `FileSink`.
- The returned rotation object itself is the shared `@file_model.FileRotation` model, not a runtime-owned concrete type.
- Non-file runtime variants return `None`.
- This helper is useful when callers need the active direct runtime policy rather than only a boolean flag.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Rotation Parameters

When diagnostics should include the active file rotation policy:
```moonbit
let rotation = sink.file_rotation_config()
```

In this example, the runtime sink exposes live rotation parameters directly.

#### When Branch On Optional Rotation Presence

When code should react differently for rotating file sinks:
```moonbit
match sink.file_rotation_config() {
  Some(cfg) => ignore(cfg)
  None => ()
}
```

In this example, the optional return shape reflects whether rotation is active.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `None`.

- If callers only need to know whether rotation is enabled, `file_rotation_enabled()` is the simpler API.

### Notes

1. Use this helper when current direct runtime rotation parameters matter.

2. It is useful after policy updates or recovery flows.
