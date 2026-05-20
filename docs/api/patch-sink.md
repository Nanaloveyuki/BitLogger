---
name: patch-sink
group: api
category: sink
update-time: 20260520
description: Create a sink that rewrites records with a patch before forwarding them.
key-word:
    - sink
    - patch
    - record
    - public
---

## Patch-sink

Create a sink that rewrites each record with a `RecordPatch` before forwarding it to another sink. This helper is the sink-level counterpart to `Logger::with_patch(...)`.

### Interface

```moonbit
pub fn[S] patch_sink(sink : S, patch : RecordPatch) -> PatchSink[S] {
```

#### input

- `sink : S` - Wrapped sink receiving patched records.
- `patch : RecordPatch` - Record transformation applied before forwarding.

#### output

- `PatchSink[S]` - Patch-applying sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- Each record is transformed before it reaches the wrapped sink.
- This helper is useful for sink-first composition graphs and adapters.
- Use the logger-level helper when the patch should be attached after `Logger::new(...)` instead.

### How to Use

Here are some specific examples provided.

#### When Need Record Rewriting At Sink Construction Time

When sanitization or target rewriting should happen before sink delivery:
```moonbit
let sink = patch_sink(console_sink(), prefix_message("[safe] "))
let logger = Logger::new(sink, target="auth")
```

In this example, records are patched before they are written to the wrapped sink.

### Error Case

e.g.:
- If patching should be attached to an already-built logger, use `with_patch(...)` instead.

- Patch behavior is defined by the supplied function, so semantic mistakes come from patch logic rather than sink mechanics.

### Notes

1. This helper is useful for explicit sink graphs.

2. It composes naturally with helpers such as `compose_patches(...)`.
