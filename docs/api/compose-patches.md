---
name: compose-patches
group: api
category: patching
update-time: 20260512
description: Create a reusable record patch pipeline from several ordered patches.
key-word:
    - patch
    - compose
    - pipeline
    - public
---

## Compose-patches

Create a `RecordPatch` that applies several patches in order. This helper is the standard way to build deterministic record transformation pipelines.

### Interface

```moonbit
pub fn compose_patches(patches : Array[RecordPatch]) -> RecordPatch {}
```

#### input

- `patches : Array[RecordPatch]` - Patches applied sequentially from first to last.

#### output

- `RecordPatch` - Patch that returns the final record after every nested patch has run.

### Explanation

Detailed rules explaining key parameters and behaviors

- Composition is ordered: each patch receives the result of the previous patch.
- Later patches can overwrite changes made by earlier patches.
- If the patch array is empty, the returned patch behaves like `identity_patch()`.
- This helper is useful for combining normalization, enrichment, and redaction into one reusable unit.

### How to Use

Here are some specific examples provided.

#### When Build A Stable Rewrite Pipeline

When a logger needs several transformations in one place:
```moonbit
let patch = compose_patches([
  set_target("api.gateway"),
  prefix_message("[safe] "),
  redact_fields(["token", "password"]),
])
```

In this example, target rewrite, message prefixing, and field redaction happen in fixed order.

#### When Reuse The Same Policy Across Loggers

When several sinks should share one transformation bundle:
```moonbit
let shared_patch = compose_patches([
  append_fields([field("service", "billing")]),
  redact_field("secret"),
])
```

In this example, the composed patch can be attached to multiple loggers without repeating inline closures.

### Error Case

e.g.:
- If `patches` is empty, the returned patch leaves records unchanged.

- If several patches rewrite the same property, the last patch in the array determines the final value.

### Notes

1. Keep patch order explicit because composition semantics are intentionally sequential.

2. Prefer one composed patch over many ad hoc inline wrappers when the transformation policy is shared.

