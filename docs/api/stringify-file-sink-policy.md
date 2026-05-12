---
name: stringify-file-sink-policy
group: api
category: runtime
update-time: 20260512
description: Serialize FileSinkPolicy into compact or pretty JSON text for diagnostics and policy snapshots.
key-word:
    - file
    - policy
    - stringify
    - public
---

## Stringify-file-sink-policy

Serialize `FileSinkPolicy` into JSON text. This helper is the most direct export path for runtime file policy snapshots.

### Interface

```moonbit
pub fn stringify_file_sink_policy(policy : FileSinkPolicy, pretty~ : Bool = false) -> String {}
```

#### input

- `policy : FileSinkPolicy` - File sink runtime policy to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON.
- `pretty=true` returns indented JSON for human inspection.
- This helper builds on top of `file_sink_policy_to_json(...)`.
- The output is suited for support dumps, policy snapshots, and generated diagnostics text.

### How to Use

Here are some specific examples provided.

#### When Need Human-readable Policy Output

When current file policy should be printed for diagnostics:
```moonbit
println(stringify_file_sink_policy(sink.policy(), pretty=true))
```

In this example, the runtime file policy is rendered in readable JSON.

#### When Need Compact Policy Export

When a file policy snapshot should stay small:
```moonbit
let text = stringify_file_sink_policy(sink.policy())
```

In this example, compact JSON is produced without extra formatting logic.

### Error Case

e.g.:
- If callers need a `JsonValue` for composition rather than text, `file_sink_policy_to_json(...)` is the better API.

- If rotation is disabled, the output still includes `rotation` as `null`.

### Notes

1. Use this helper for direct textual policy snapshots.

2. `pretty=true` is useful when operators or support tooling are the audience.
