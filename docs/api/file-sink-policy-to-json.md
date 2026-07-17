---
name: file-sink-policy-to-json
group: api
category: runtime
update-time: 20260512
description: Convert FileSinkPolicy into a JSON value for runtime diagnostics, policy snapshots, or transport.
key-word:
    - file
    - policy
    - json
    - public
---

## File-sink-policy-to-json

Convert `FileSinkPolicy` into a `Json`. On the root `src` facade, this helper forwards to the concrete serializer owned by `src/file_model`.

### Interface

```moonbit
pub fn file_sink_policy_to_json(policy : FileSinkPolicy) -> Json {}
```

#### input

- `policy : FileSinkPolicy` - File sink runtime policy to export.

#### output

- `Json` - Structured JSON representation of the file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `append`, `auto_flush`, and `rotation`.
- The root surface forwards to `@file_model.file_sink_policy_to_json(...)`, which is the real owner of this serialization logic.
- `rotation` is exported as `null` when rotation is disabled.
- This helper exports runtime file policy, not current file health counters or availability.
- The JSON value is useful for policy snapshots, comparisons, and diagnostics payloads.
- Typical inputs come from `FileSink::policy()`, `RuntimeSink::file_policy()`, or `ConfiguredLogger::file_policy()`.
- If the active rotation policy originated from `file_rotation_i64(...)`, the nested rotation JSON includes both the compatibility `max_bytes` number and `max_bytes_i64` as the exact string form.

### How to Use

Here are some specific examples provided.

#### When Need Structured Policy Snapshots

When file policy should be embedded into a larger JSON payload:
```moonbit
let value = file_sink_policy_to_json(runtime.file_policy())
```

In this example, the runtime file policy becomes a reusable structured value.

#### When Need Policy Comparison Data

When current and default policy should be exported separately:
```moonbit
let current = file_sink_policy_to_json(runtime.file_policy())
let defaults = file_sink_policy_to_json(runtime.file_default_policy())
```

In this example, callers can compare current and default policy snapshots without formatting text first.

### Error Case

e.g.:
- If rotation is disabled, the exported `rotation` field is `null` rather than omitted.

- If callers need direct text output, `stringify_file_sink_policy(...)` is the better API.

### Notes

1. Use this helper when downstream code expects `Json` rather than text.

2. It pairs naturally with `FileSink::policy()`, `RuntimeSink::file_policy()`, and related default-policy accessors.

3. For wide native rotation policies, downstream code should read `rotation.max_bytes_i64` when exact threshold recovery matters.
