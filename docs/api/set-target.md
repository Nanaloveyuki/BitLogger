---
name: set-target
group: api
category: patching
update-time: 20260512
description: Create a reusable record patch that rewrites the target field.
key-word:
    - patch
    - target
    - transform
    - public
---

## Set-target

Create a `RecordPatch` that rewrites `rec.target` to a fixed string. Use it when records should be reclassified or routed under a normalized target.

### Interface

```moonbit
pub fn set_target(target : String) -> RecordPatch {}
```

#### input

- `target : String` - Target value that should replace the original record target.

#### output

- `RecordPatch` - Patch that returns a record with the new target.

### Explanation

Detailed rules explaining key parameters and behaviors

- The patch copies the original record and replaces only its `target`.
- Message, level, timestamp, and fields are preserved.
- This helper is useful when several call sites should appear under one logical namespace.
- It can be combined with `prefix_message(...)` or `append_fields(...)` in ordered pipelines.

### How to Use

Here are some specific examples provided.

#### When Normalize Child Targets

When several producers should share one target label:
```moonbit
let logger = Logger::new(console_sink(), target="worker")
  .with_patch(set_target("worker.batch"))
```

In this example, downstream filters and sinks only see `worker.batch`.

#### When Redirect Records Before Fanout

When a routing layer expects one canonical target:
```moonbit
let patch = compose_patches([
  set_target("audit"),
  append_fields([field("source", "legacy")]),
])
```

In this example, reclassification and enrichment happen in a predictable order.

### Error Case

e.g.:
- If `target` is empty, the patch still rewrites the record target to an empty string.

- If later patches also rewrite the target, the last applied patch wins.

### Notes

1. Use this helper for target normalization, not for filtering decisions.

2. Prefer explicit patch order when multiple target rewrites are possible.

