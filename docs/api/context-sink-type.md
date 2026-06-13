---
name: context-sink-type
group: api
category: sink
update-time: 20260613
description: Public context sink type used for prepending shared structured fields to records before forwarding.
key-word:
    - sink
    - context
    - type
    - public
---

## Context-sink-type

`ContextSink[S]` is the public context wrapper sink type used for prepending shared structured fields to records before forwarding them to another sink. It is the concrete sink type introduced by logger helpers such as `with_context_fields(...)` and `bind(...)`, and it preserves the wrapped sink type in its type parameter.

### Interface

```moonbit
pub struct ContextSink[S] {
  sink : S
  context_fields : Array[Field]
}
```

#### output

- `ContextSink[S]` - Public synchronous sink type that merges shared fields into each record before forwarding it to the wrapped sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `sink : S` and `context_fields : Array[Field]`.
- `Logger::with_context_fields(...)` and `Logger::bind(...)` produce logger values whose sink type becomes `ContextSink[S]`.
- The sink preserves the wrapped sink type `S`, which is useful when typed composition still matters after shared-field injection is introduced.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Context-wrapping Logger

When logging should preserve the shared-field wrapper sink type in the logger:
```moonbit
let logger : Logger[ContextSink[ConsoleSink]] = Logger::new(console_sink())
  .with_context_fields([field("service", "billing")])
```

In this example, the concrete context wrapper sink remains part of the logger type.

#### When Need Stable Shared Metadata On A Wrapped Sink

When code should keep sink typing explicit after field binding:
```moonbit
let worker = Logger::new(console_sink(), target="app")
  .with_context_fields([field("component", "worker")])
```

In this example, shared metadata is injected through the context wrapper instead of being repeated on each write call.

### Error Case

e.g.:
- `ContextSink[S]` itself does not have a runtime failure mode.

- Actual write behavior still depends on the wrapped sink `S`, and duplicate or empty context fields are still forwarded as structured data.

### Notes

1. Use logger helpers such as `with_context_fields(...)` or `bind(...)` when you need a value whose sink type is `ContextSink[S]`.

2. Use the logger-level APIs rather than constructing this sink shape manually in normal calling code.
