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

Convert `FileSinkPolicy` into a `JsonValue`. This helper exports append mode, auto-flush, and optional rotation as a structured runtime policy snapshot.

### Interface

```moonbit
pub fn file_sink_policy_to_json(policy : FileSinkPolicy) -> @json_parser.JsonValue {}
```

#### input

- `policy : FileSinkPolicy` - File sink runtime policy to export.

#### output

- `JsonValue` - Structured JSON representation of the file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `append`, `auto_flush`, and `rotation`.
- `rotation` is exported as `null` when rotation is disabled.
- This helper exports runtime file policy, not current file health counters or availability.
- The JSON value is useful for policy snapshots, comparisons, and diagnostics payloads.

### How to Use

Here are some specific examples provided.

#### When Need Structured Policy Snapshots

When file sink policy should be embedded into a larger JSON payload:
```moonbit
let value = file_sink_policy_to_json(sink.policy())
```

In this example, the runtime file policy becomes a reusable structured value.

#### When Need Policy Comparison Data

When current and default policy should be exported separately:
```moonbit
let current = file_sink_policy_to_json(sink.policy())
```

In this example, callers can compare policy snapshots without formatting text first.

### Error Case

e.g.:
- If rotation is disabled, the exported `rotation` field is `null` rather than omitted.

- If callers need direct text output, `stringify_file_sink_policy(...)` is the better API.

### Notes

1. Use this helper when downstream code expects `JsonValue` rather than text.

2. It pairs naturally with `policy()` and `default_policy()` runtime accessors.
