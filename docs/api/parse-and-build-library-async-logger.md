---
name: parse-and-build-library-async-logger
group: api
category: facade
update-time: 20260520
description: Parse JSON async build config text and build the library-facing async logger facade.
key-word:
    - library
    - async
    - parse
    - public
---

## Parse-and-build-library-async-logger

Parse raw JSON async build config text and build a `LibraryAsyncLogger[RuntimeSink]` in one step. This facade is the text-driven library counterpart to the general async config parser plus builder flow.

### Interface

```moonbit
pub fn parse_and_build_library_async_logger(
  input : String,
) -> LibraryAsyncLogger[RuntimeSink] raise {
```

#### input

- `input : String` - Raw JSON async logger build config text.

#### output

- `LibraryAsyncLogger[RuntimeSink]` - Library-facing async runtime logger wrapper.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API parses async build config text, validates it, builds the async runtime logger, and narrows it to the library facade.
- The resulting facade keeps async lifecycle helpers while exposing a smaller public surface.
- `to_async_logger()` can recover the underlying async logger when a wider API is required.

### How to Use

Here are some specific examples provided.

#### When Need Text-driven Async Library Bootstrapping

When a package accepts raw config text but wants a narrower async facade output:
```moonbit
let logger = parse_and_build_library_async_logger(
  "{\"logger\":{\"target\":\"lib.async\",\"sink\":{\"kind\":\"console\"}},\"async_config\":{\"max_pending\":4,\"overflow\":\"DropNewest\",\"max_batch\":1,\"linger_ms\":0,\"flush\":\"Never\"}}",
)
```

In this example, parsing and library-facade construction happen together.

### Error Case

e.g.:
- If the JSON text is malformed, parsing raises an error.

- If the embedded config is invalid, parsing raises before the library facade is returned.

### Notes

1. This is the narrow async library parse-and-build facade.

2. Use `build_library_async_logger(...)` when the config is already typed.
