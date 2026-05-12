---
name: append-fields
group: api
category: patching
update-time: 20260512
description: Create a reusable record patch that appends extra fields to the record.
key-word:
    - patch
    - fields
    - transform
    - public
---

## Append-fields

Create a `RecordPatch` that appends extra fields to `rec.fields`. Use it when records should be enriched with stable metadata before reaching sinks.

### Interface

```moonbit
pub fn append_fields(extra_fields : Array[Field]) -> RecordPatch {}
```

#### input

- `extra_fields : Array[Field]` - Fields appended after the record's existing field list.

#### output

- `RecordPatch` - Patch that returns a record with appended fields.

### Explanation

Detailed rules explaining key parameters and behaviors

- If `extra_fields` is empty, the patch returns the original record unchanged.
- If the original record has no fields, the appended fields become the new field list.
- Otherwise, the original fields stay first and `extra_fields` are appended afterward.
- This helper is useful for environment tags, service metadata, and bridge-layer context.

### How to Use

Here are some specific examples provided.

#### When Add Service Metadata

When every record should carry shared context:
```moonbit
let logger = Logger::new(console_sink())
  .with_patch(append_fields([
    field("service", "billing"),
    field("region", "cn"),
  ]))
```

In this example, the extra fields are added to every emitted record.

#### When Compose With Message Rewriting

When both visible and structured context are needed:
```moonbit
let patch = compose_patches([
  prefix_message("[api] "),
  append_fields([field("component", "gateway")]),
])
```

In this example, the record gains both textual and structured enrichment.

### Error Case

e.g.:
- If `extra_fields` is empty, the patch behaves like a no-op.

- If appended field keys duplicate existing keys, both copies remain in the field list.

### Notes

1. This helper appends fields; it does not deduplicate or overwrite existing entries.

2. Field order can matter for downstream formatting or inspection, so keep appended context intentional.

