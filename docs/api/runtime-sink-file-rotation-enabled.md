---
name: runtime-sink-file-rotation-enabled
group: api
category: runtime
update-time: 20260613
description: Read whether rotation is currently enabled on a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-rotation-enabled

Read whether rotation is currently enabled on a file-backed `RuntimeSink`. This helper exposes direct runtime rotation state without requiring a `ConfiguredLogger` wrapper.

### Interface

```moonbit
pub fn RuntimeSink::file_rotation_enabled(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose file rotation state should be inspected.

#### output

- `Bool` - Whether rotation is currently enabled.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report whether the wrapped `FileSink` currently has a rotation config.
- `QueuedFile` runtime variants forward the state from the wrapped inner `FileSink`.
- Non-file runtime variants return `false`.
- This helper is narrower than `file_rotation_config()` when callers only need a yes-or-no answer.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Rotation Visibility

When code owns a `RuntimeSink` directly and should expose whether rotation is active:
```moonbit
let rotating = sink.file_rotation_enabled()
```

In this example, runtime rotation state is checked without inspecting an optional config value.

#### When Guard Rotation-specific Direct Logic

When code should branch only for rotating file sinks:
```moonbit
if sink.file_rotation_enabled() {
  println("rotation active")
}
```

In this example, direct runtime policy drives control flow.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need the actual rotation parameters, `file_rotation_config()` is the better API.

### Notes

1. Use this helper for simple direct runtime rotation checks.

2. Pair it with `file_rotation_config()` when policy details also matter.
