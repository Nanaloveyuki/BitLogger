---
name: stringify-queue-config
group: api
category: config
update-time: 20260512
description: Serialize QueueConfig into compact or pretty JSON text for config output and diagnostics.
key-word:
    - queue
    - config
    - stringify
    - public
---

## Stringify-queue-config

Serialize `QueueConfig` into JSON text. This helper is the most direct export path for synchronous queue wrapper configuration when callers want immediate string output.

### Interface

```moonbit
pub fn stringify_queue_config(queue : QueueConfig, pretty~ : Bool = false) -> String {}
```

#### input

- `queue : QueueConfig` - Queue wrapper configuration to serialize.
- `pretty : Bool` - Whether JSON should be pretty-printed.

#### output

- `String` - Serialized JSON text for the queue config.

### Explanation

Detailed rules explaining key parameters and behaviors

- `pretty=false` returns compact JSON suitable for logs and snapshots.
- `pretty=true` returns indented JSON for human inspection.
- This helper is built on top of `queue_config_to_json(...)`.
- Internally it serializes the `JsonValue` result with `@json_parser.stringify(...)` or `@json_parser.stringify_pretty(value, 2)`, so the text form stays aligned with the structured export helper.
- The resulting text follows the same queue schema accepted by config parsing flows.

### How to Use

Here are some specific examples provided.

#### When Need Config Text For Humans

When queue settings should be printed or pasted into docs:
```moonbit
println(stringify_queue_config(QueueConfig::new(32), pretty=true))
```

In this example, the output is formatted for readability.

#### When Need Compact Generated Output

When queue config should stay small:
```moonbit
let text = stringify_queue_config(
  QueueConfig::new(8, overflow=QueueOverflowPolicy::DropNewest),
)
```

In this example, compact JSON is returned without extra formatting.

### Error Case

e.g.:
- If callers need a `JsonValue` for further composition, this API is the wrong layer and `queue_config_to_json(...)` should be used instead.

- If queue policy is too aggressive for workload burst size, serialization still succeeds because this helper only exports config.

### Notes

1. Use this helper when the next consumer expects JSON text instead of `JsonValue`.

2. Use `queue_config_to_json(...)` when you still need to embed the queue config inside a larger JSON object before final stringification.

