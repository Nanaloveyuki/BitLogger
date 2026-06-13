---
name: patch-sink-type
group: api
category: sink
update-time: 20260613
description: Public patch sink type used for record-rewriting forwarding over another sink.
key-word:
    - sink
    - patch
    - type
    - public
---

## Patch-sink-type

`PatchSink[S]` is the public record-rewriting sink type used for forwarding patched records to another sink. It is the concrete sink type returned by `patch_sink(...)` and preserves the wrapped sink type in its type parameter.

### Interface

```moonbit
pub struct PatchSink[S] {
  sink : S
  patch : RecordPatch
}
```

#### output

- `PatchSink[S]` - Public synchronous sink type that rewrites records before forwarding them to the wrapped sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `sink : S` and `patch : RecordPatch`.
- `patch_sink(...)` constructs this type directly from a wrapped sink and patch function.
- The sink preserves the wrapped sink type `S`, which is useful when typed composition still matters after record rewriting is introduced.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Record-rewriting Sink Value

When code should keep the concrete patch wrapper sink type visible:
```moonbit
let sink : PatchSink[ConsoleSink] = patch_sink(console_sink(), prefix_message("[safe] "))
```

In this example, the sink value stays explicit and preserves the wrapped console sink type.

#### When Need A Typed Logger With Sink-level Patching

When logging should preserve the patch wrapper sink type in the logger:
```moonbit
let logger : Logger[PatchSink[ConsoleSink]] = Logger::new(
  patch_sink(console_sink(), set_target("audit")),
)
```

In this example, the concrete patch sink remains part of the logger type.

### Error Case

e.g.:
- `PatchSink[S]` itself does not have a runtime failure mode.

- Runtime behavior still depends on the wrapped sink `S`, and semantic rewrite mistakes come from the supplied patch function rather than the type itself.

### Notes

1. Use `patch_sink(...)` when you need a value of this type.

2. Use `FilterSink[S]` when records should be conditionally dropped rather than rewritten.
