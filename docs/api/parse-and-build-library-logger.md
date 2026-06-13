---
name: parse-and-build-library-logger
group: api
category: facade
update-time: 20260613
description: Parse JSON logger config text and build the library-facing sync logger facade by delegating to the configured runtime logger parse-and-build path and then wrapping the result.
key-word:
    - library
    - facade
    - parse
    - public
---

## Parse-and-build-library-logger

Parse raw JSON config text and build a `LibraryLogger[RuntimeSink]` in one step. This facade is the text-driven library counterpart to `parse_and_build_logger(...)` plus library-surface narrowing.

### Interface

```moonbit
pub fn parse_and_build_library_logger(
  input : String,
) -> LibraryLogger[RuntimeSink] raise ConfigError {
```

#### input

- `input : String` - Raw JSON logger config text.

#### output

- `LibraryLogger[RuntimeSink]` - Library-facing wrapper around the configured runtime logger.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API parses config text, validates it, builds the configured logger through `parse_and_build_logger(...)`, and wraps that same value as a library facade.
- The parsed config still goes through the normal configured runtime logger build path, including runtime sink selection, optional queue wrapping, and timestamp application.
- The returned facade keeps a narrower surface than the underlying configured logger.
- Queue metrics, flush and drain helpers, and file runtime controls stay on the underlying `ConfiguredLogger`, not on the returned facade itself.
- `to_logger()` can be used to recover the underlying full logger object when necessary.

### How to Use

Here are some specific examples provided.

#### When Need Text-driven Library Bootstrapping

When a reusable package wants config text input but a narrow logger facade output:
```moonbit
let logger = parse_and_build_library_logger(
  "{\"min_level\":\"warn\",\"target\":\"lib\",\"sink\":{\"kind\":\"console\"}}",
)
```

In this example, parsing and library-facade construction happen in one call.

#### When Need Runtime Helpers After Text-driven Library Bootstrapping

When JSON-driven construction should still allow internal runtime inspection later:
```moonbit
let logger = parse_and_build_library_logger(raw) catch {
  err => return
}
let full = logger.to_logger()
ignore(full.pending_count())
```

In this example, the caller unwraps the library facade before using configured runtime helper methods.

And the unwrapped value still reflects the same `RuntimeSink` pipeline built from the parsed config text.

### Error Case

e.g.:
- If the JSON text is malformed, a `ConfigError` is raised.

- If the parsed config is invalid, a `ConfigError` is raised before the library facade is returned.

- If callers assume configured runtime helper methods are available directly on the returned facade, they must unwrap first with `to_logger()`.

### Notes

1. This is the narrow library-oriented parse-and-build sync entry point.

2. Use `build_library_logger(...)` when the config is already typed.

3. Use `to_logger()` when internal code later needs configured-runtime helpers or broader logger composition without changing the public facade type.
