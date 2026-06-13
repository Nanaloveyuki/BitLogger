---
name: default-library-logger
group: api
category: facade
update-time: 20260520
description: Create the default library-facing console logger facade by wrapping the current shared default logger at call time.
key-word:
    - library
    - facade
    - default
    - public
---

## Default-library-logger

Create a `LibraryLogger[ConsoleSink]` from the current shared default console logger settings. This is the narrow library-facing counterpart to `default_logger()`.

### Interface

```moonbit
pub fn default_library_logger() -> LibraryLogger[ConsoleSink] {
```

#### output

- `LibraryLogger[ConsoleSink]` - Library-facing console logger built from the current shared defaults.

### Explanation

Detailed rules explaining key parameters and behaviors

- This API wraps `default_logger()` as a library facade.
- Each call reflects the current shared default minimum level and default target at that moment.
- The returned value exposes the narrower `LibraryLogger` surface rather than the full `Logger` surface.
- Later changes to shared defaults do not mutate an already-created facade value because the wrapped logger is captured when `default_library_logger()` is called.

### How to Use

Here are some specific examples provided.

#### When Need A Default Logger But Want A Narrower Facade

When a library should adopt the shared console defaults without exposing the full logger type:
```moonbit
let logger = default_library_logger()
if logger.is_enabled(Level::Info) {
  logger.info("ready")
}
```

In this example, the library facade mirrors the current global defaults.

And if the caller later unwraps it with `to_logger()`, the same captured default target and minimum level are still present on the full logger value.

### Error Case

e.g.:
- If the shared default target is empty, the returned logger is still valid.

- Later changes to shared defaults do not mutate an already-created facade value.

### Notes

1. Use `to_logger()` if callers need the full sync logger surface.

2. This helper is useful for library-facing APIs that should stay narrower than `Logger`.

3. Call `default_library_logger()` again after shared default changes if a fresh facade value should reflect the new defaults.
