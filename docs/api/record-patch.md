---
name: record-patch
group: api
category: helper
update-time: 20260613
description: Public patch function type used for record transformation before sink write.
key-word:
    - patch
    - record
    - transform
    - public
---

## Record-patch

`RecordPatch` is the public function type used for record transformation. It represents any function that receives a `Record` and returns a new `Record`, and it is the shared shape behind helpers such as `set_target(...)`, `prefix_message(...)`, and `append_fields(...)`.

### Interface

```moonbit
pub type RecordPatch = @utils.RecordPatch
```

#### output

- `RecordPatch` - A function type equivalent to `(Record) -> Record`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a new runtime wrapper.
- Any function matching `(Record) -> Record` can be used wherever a `RecordPatch` is expected.
- Patches are used by `Logger::with_patch(...)`, `patch_sink(...)`, and helper constructors in `patchers.mbt`.
- The alias exists to make record-rewrite APIs clearer and easier to read in public signatures.

### How to Use

Here are some specific examples provided.

#### When Need A Custom Record Rewrite Step

When a logger should rewrite each record before sink write:
```moonbit
let patch : RecordPatch = fn(rec) { rec.with_message("[custom] " + rec.message) }
let logger = Logger::new(console_sink()).with_patch(patch)
```

In this example, the alias makes the custom transformation shape explicit.

#### When Compose Existing Patch Helpers

When several reusable transformations should be combined:
```moonbit
let patch : RecordPatch = compose_patches([
  set_target("service.worker"),
  prefix_message("[worker] "),
])
```

In this example, the alias describes the common type returned by the patch helper constructors.

### Error Case

e.g.:
- A patch that drops important fields or overwrites the target can change downstream observability unexpectedly.

- A patch that allocates heavily or copies too much data can add cost to every write path.

### Notes

1. Use the alias when function signatures should communicate transformation intent clearly.

2. Helper constructors in `patchers.mbt` are usually preferable to handwritten patches for common cases.
