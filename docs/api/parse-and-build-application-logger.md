---
name: parse-and-build-application-logger
group: api
category: facade
update-time: 20260520
description: Parse JSON logger config text and build the application-facing sync logger facade.
key-word:
    - application
    - facade
    - parse
    - public
---

## Parse-and-build-application-logger

Parse raw JSON config text and build an `ApplicationLogger` in one step. This facade is the application-oriented counterpart to `parse_and_build_logger(...)`.

### Interface

```moonbit
pub fn parse_and_build_application_logger(
  input : String,
) -> ApplicationLogger raise ConfigError {
```

#### input

- `input : String` - Raw JSON logger config text.

#### output

- `ApplicationLogger` - Application-facing configured runtime logger built from parsed config.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API delegates to `parse_and_build_logger(...)`.
- JSON parsing and config validation happen before the logger is built.
- The returned logger keeps the same queue and file helper surface as other configured sync runtime loggers.

### How to Use

Here are some specific examples provided.

#### When Need Direct JSON Bootstrapping For Applications

When config is stored as text and should be built immediately:
```moonbit
let logger = parse_and_build_application_logger(
  "{\"min_level\":\"warn\",\"target\":\"app\",\"sink\":{\"kind\":\"console\"}}",
)
```

In this example, parsing and runtime construction are combined into one facade call.

### Error Case

e.g.:
- If the JSON is malformed, a `ConfigError` is raised.

- If the parsed config is invalid, such as an empty file sink path, a `ConfigError` is raised.

### Notes

1. Use this facade when application code wants a text-to-runtime entry point.

2. Use `build_application_logger(...)` when the config is already typed as `LoggerConfig`.
