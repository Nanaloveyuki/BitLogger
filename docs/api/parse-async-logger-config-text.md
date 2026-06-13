---
name: parse-async-logger-config-text
group: api
category: async
update-time: 20260614
description: Parse JSON text into an AsyncLoggerConfig, applying async config defaults and accepted policy aliases.
key-word:
    - async
    - config
    - parse
    - public
---

## Parse-async-logger-config-text

Parse raw JSON text into `AsyncLoggerConfig`. This helper is the text-entry counterpart to `AsyncLoggerConfig::new(...)` when async queue and flush policy should be configured from serialized data.

### Interface

```moonbit
pub fn parse_async_logger_config_text(input : String) -> AsyncLoggerConfig raise {
```

#### input

- `input : String` - Raw JSON text describing async queue, batching, linger, and flush settings.

#### output

- `AsyncLoggerConfig` - Parsed async runtime config value.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper parses only the async config portion, not the embedded sync `LoggerConfig`.
- Missing `max_pending`, `overflow`, `max_batch`, `linger_ms`, and `flush` fields fall back to the same defaults used by `AsyncLoggerConfig::new(...)`.
- Parsed values then flow through `AsyncLoggerConfig::new(...)`, so `max_batch` and `linger_ms` receive the same constructor normalization.
- Overflow parsing accepts both `DropNewest` and the compatibility alias `DropLatest`.
- Flush parsing accepts both `Never` and the compatibility alias `None`.
- Use this API when async policy comes from config text but sink choice is still assembled elsewhere.

### How to Use

Here are some specific examples provided.

#### When Need Async Queue Policy From JSON

When async queue behavior is loaded separately from sync sink config:
```moonbit
let config = parse_async_logger_config_text(
  "{\"max_pending\":8,\"overflow\":\"DropOldest\",\"max_batch\":3,\"linger_ms\":25,\"flush\":\"Batch\"}",
)
```

In this example, async queue and flush policy are parsed from text into a typed config object.

#### When Need Alias-friendly Async Policy Parsing

When external config may use compatibility labels:
```moonbit
let config = parse_async_logger_config_text(
  "{\"overflow\":\"DropLatest\",\"flush\":\"None\"}",
)
```

In this example, parser aliases are accepted and normalized into the public enum values.

### Error Case

e.g.:
- If the JSON text is malformed, parsing raises an error.

- If enum names such as `overflow` or `flush` are unsupported, parsing raises an error.

- If a field is present with the wrong JSON type, parsing raises an error instead of silently coercing it.

### Notes

1. Use this helper when only async policy is text-driven.

2. Use `parse_async_logger_build_config_text(...)` when both sync logger config and async config come from the same JSON payload.

3. Omitted fields fall back to the default async config values rather than causing a missing-field error.
