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

Convert `FileRotation` into a `JsonValue`. On the root `src` facade, this helper forwards to the concrete serializer owned by `src/file_model`.

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

- The output always includes `max_bytes` and `max_backups`.
- The root surface forwards to `@file_model.file_rotation_config_to_json(...)`, which is the real owner of this serialization logic.
- Both of those compatibility fields are exported as JSON numbers.
- If the policy carries a wide threshold from `file_rotation_i64(...)`, the output also includes `max_bytes_i64` as a JSON string for exact roundtrip transport.
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

#### When Need Exact Wide-threshold Roundtrip

When a native large-file policy should preserve the original `Int64` threshold in JSON:
```moonbit
let rotation = file_rotation_i64(4294967296L, max_backups=2)
let rotation_json = file_rotation_config_to_json(rotation)
```

In this example, the JSON value includes the compatibility `max_bytes` view plus `max_bytes_i64` as a string.

### Error Case

e.g.:
- If callers need a complete sink or logger config snapshot, this helper alone is too narrow and should be paired with `sink_config_to_json(...)` or `logger_config_to_json(...)`.

- If callers need text output rather than a JSON value, they should stringify a larger containing config instead of manually formatting this value.

### Notes

1. Use this helper when downstream code expects `JsonValue` rather than a typed `FileRotation` value.

2. Pair it with `file_rotation(...)` when building rotation policy in code before export.

3. For `file_rotation_i64(...)`, treat `max_bytes_i64` as the exact roundtrip field and `max_bytes` as the compatibility view.
