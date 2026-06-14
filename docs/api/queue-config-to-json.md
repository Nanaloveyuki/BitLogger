---
name: queue-config-to-json
group: api
category: config
update-time: 20260512
description: Convert QueueConfig into a JSON value for export, persistence, or generated config tooling.
key-word:
    - queue
    - config
    - json
    - public
---

## Queue-config-to-json

Convert a typed `QueueConfig` into a `JsonValue`. This helper is the structured export path for synchronous queue wrapper configuration when callers want machine-readable config output.

### Interface

```moonbit
pub fn queue_config_to_json(queue : QueueConfig) -> @json_parser.JsonValue {}
```

#### input

- `queue : QueueConfig` - Queue wrapper configuration created in code or parsed from config text.

#### output

- `JsonValue` - Structured JSON representation of the queue config.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `max_pending` and `overflow`.
- Overflow is serialized using the supported config labels such as `DropNewest` and `DropOldest`.
- `max_pending` is emitted as a JSON number and `overflow` is emitted as the stable parser-facing text label, so the result stays aligned with `parse_logger_config_text(...)` roundtrips.
- This helper is intended for config export rather than runtime queue inspection.
- The JSON shape matches the queue section accepted by `parse_logger_config_text(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Structured Queue Config Export

When queue settings should be embedded into a larger JSON payload:
```moonbit
let queue_json = queue_config_to_json(
  QueueConfig::new(64, overflow=QueueOverflowPolicy::DropOldest),
)
```

In this example, callers receive a reusable JSON value instead of a final string.

#### When Need Roundtrip-friendly Config Data

When code generates queue policy and later persists it:
```moonbit
let value = queue_config_to_json(QueueConfig::new(16))
```

In this example, the exported shape stays aligned with the supported parser schema.

### Error Case

e.g.:
- If `max_pending` is very small, the config still serializes successfully even though runtime drops may happen more often.

- If callers need direct text output instead of a JSON value, they should use `stringify_queue_config(...)` instead.

### Notes

1. Use this helper when you need a reusable JSON value rather than a final JSON string.

2. Use `stringify_queue_config(...)` when the next consumer expects text instead of `JsonValue`.

