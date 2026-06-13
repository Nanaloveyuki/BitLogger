---
name: file-rotation-config-to-json
group: api
category: config
update-time: 20260613
description: Convert FileRotation into a JSON value for config export and nested sink serialization.
key-word:
    - file
    - rotation
    - json
    - public
---

## File-rotation-config-to-json

Convert `FileRotation` into a `JsonValue`. This helper is the structured export path for file rotation policy when callers need machine-readable config data instead of a runtime policy object.

### Interface

```moonbit
pub fn file_rotation_config_to_json(config : FileRotation) -> @json_parser.JsonValue {}
```

#### input

- `config : FileRotation` - File rotation config value to export.

#### output

- `JsonValue` - Structured JSON representation of the rotation policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output includes `max_bytes` and `max_backups`.
- Both numeric fields are exported as JSON numbers.
- This helper serializes the rotation config object itself rather than sink availability, failure counters, or file state.
- The same JSON shape is reused by `sink_config_to_json(...)`, file sink state export helpers, and larger logger config serialization paths.

### How to Use

Here are some specific examples provided.

#### When Need Structured Rotation Policy Export

When file rotation settings should be embedded into a larger config payload:
```moonbit
let value = file_rotation_config_to_json(file_rotation(1024 * 1024, max_backups=3))
```

In this example, the rotation policy becomes a reusable JSON value instead of final text.

#### When Need Manual Sink Config Assembly

When code is exporting only the rotation portion of a file-related config flow:
```moonbit
let rotation = file_rotation(4096, max_backups=2)
let rotation_json = file_rotation_config_to_json(rotation)
```

In this example, callers can carry the nested rotation shape without exporting a full sink config.

### Error Case

e.g.:
- If callers need a complete sink or logger config snapshot, this helper alone is too narrow and should be paired with `sink_config_to_json(...)` or `logger_config_to_json(...)`.

- If callers need text output rather than a JSON value, they should stringify a larger containing config instead of manually formatting this value.

### Notes

1. Use this helper when downstream code expects `JsonValue` rather than a typed `FileRotation` value.

2. Pair it with `file_rotation(...)` when building rotation policy in code before export.
