---
name: logger-with-patch
group: api
category: logging
update-time: 20260512
description: Wrap a logger with record transformation logic before the record reaches the sink.
key-word:
    - logger
    - patch
    - transform
    - public
---

## Logger-with-patch

Attach a `RecordPatch` to a logger so each record is transformed before it is written to the sink. This API is the standard way to rewrite target, message, or fields without changing caller code.

### Interface

```moonbit
pub fn[S] Logger::with_patch(self : Logger[S], patch : RecordPatch) -> Logger[PatchSink[S]] {}
```

#### input

- `self : Logger[S]` - Base logger to wrap.
- `patch : RecordPatch` - Record-to-record transformer applied before writing.

#### output

- `Logger[PatchSink[S]]` - A new logger that rewrites emitted records.

### Explanation

Detailed rules explaining key parameters and behaviors

- Patches can rewrite `target`, `message`, and `fields` because they receive the full `Record`.
- This API does not change logging level gating; level checks still happen at the logger level.
- `compose_patches(...)` can be used to build ordered patch pipelines.
- This is the correct place for redaction, enrichment, and message prefixing.

### How to Use

Here are some specific examples provided.

#### When Need Redaction Before Output

When sensitive data must be rewritten before reaching any sink:
```moonbit
let logger = Logger::new(console_sink(), target="auth")
  .with_patch(redact_fields(["token", "password"]))
```

In this example, matching field values are replaced before the sink sees them.

And caller code does not need custom redaction logic per log call.

#### When Need Combined Enrichment And Message Rewrite

When you want several transformations in a stable order:
```moonbit
let logger = Logger::new(console_sink(), target="svc")
  .with_patch(compose_patches([
    prefix_message("[safe] "),
    append_fields([field("service", "svc")]),
  ]))
```

In this example, patch order is explicit and deterministic.

### Error Case

e.g.:
- If a patch returns the original record unchanged, the wrapper behaves like a pass-through transformer.

- If multiple patches rewrite the same field or property, the later patch wins according to composition order.

### Notes

1. Use patches for transformation, not filtering decisions.

2. Prefer helper patches such as `prefix_message(...)`, `append_fields(...)`, and `redact_fields(...)` for common cases.

