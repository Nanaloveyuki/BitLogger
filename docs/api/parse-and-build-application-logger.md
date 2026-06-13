---
name: parse-and-build-application-logger
group: api
category: facade
update-time: 20260520
description: Parse JSON logger config text and build the application-facing sync logger alias by delegating directly to the configured runtime logger parse-and-build path.
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

- This API delegates to `parse_and_build_logger(...)` directly.
- JSON parsing and config validation happen before the logger is built.
- The parsed config still goes through the normal configured runtime logger build path, including runtime sink selection, optional queue wrapping, and timestamp application.
- Because the result is only the `ApplicationLogger` alias over `ConfiguredLogger`, this parse-and-build path returns the same underlying configured runtime logger value that `parse_and_build_logger(...)` would produce directly, without hiding any queue, drain, flush, or file runtime helper methods.
- The returned alias also keeps inherited `Logger` behavior such as `with_target(...)`, `child(...)`, and per-call `target=` overrides on `log(...)`.
- Use `parse_and_build_library_logger(...)` instead when the same parsed configured logger result should be wrapped and narrowed for a library boundary.

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

And any queue/file/runtime helpers selected by the parsed config remain directly available on the returned alias value.

The returned value also keeps the ordinary logger target semantics because this facade does not wrap or narrow the configured runtime logger result.

### Error Case

e.g.:
- If the JSON is malformed, a `ConfigError` is raised.

- If the parsed config is invalid, such as an empty file sink path, a `ConfigError` is raised.

### Notes

1. Use this facade when application code wants a text-to-runtime entry point.

2. Use `build_application_logger(...)` when the config is already typed as `LoggerConfig`.

3. Use `parse_and_build_library_logger(...)` instead when text-driven construction should narrow the public sync logger surface for a library boundary.
