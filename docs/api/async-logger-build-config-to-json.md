---
name: async-logger-build-config-to-json
group: api
category: async
update-time: 20260614
description: Convert AsyncLoggerBuildConfig into a JSON value for exporting the full shared async build shape that can later feed either async builder path.
key-word:
    - async
    - build
    - config
    - public
---

## Async-logger-build-config-to-json

Convert `AsyncLoggerBuildConfig` into a `Json`. This helper exports both the base synchronous logger config and the async runtime config as one structured payload.

### Interface

```moonbit
pub fn async_logger_build_config_to_json(
  config : AsyncLoggerBuildConfig,
) -> Json {}
```

#### input

- `config : AsyncLoggerBuildConfig` - Complete build config used by async logger builders.

#### output

- `Json` - Structured JSON representation of the full async build config.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output always includes `logger` and `async_config`.
- Logger export is delegated to `@bitlogger.logger_config_to_json(...)`.
- Async export is delegated to `async_logger_config_to_json(...)`.
- Because both sections are always materialized, parsed defaults that were originally omitted in JSON input become explicit again in the exported build-config shape.
- This helper is useful when generated setup should preserve both sink/logger behavior and async runtime behavior together.
- The exported `logger` section keeps the full `LoggerConfig` shape, including fields that only matter on the full sync-first builder path such as the optional sync queue layer.
- That means the JSON shape is broader than the consumption pattern of `build_async_text_logger(...)`, which only uses selected text-oriented logger fields when building the sink.
- In particular, the exported `logger.sink.kind` remains whatever the config currently says, but a later `build_async_text_logger(...)` call still ignores that sink-kind branch and constructs `FormattedConsoleSink` from `logger.sink.text_formatter`.
- The same exported object is also the shared handoff shape for the application and library facade routes after parse. `parse_async_logger_build_config_text(...)` can read this JSON back into `AsyncLoggerBuildConfig`, and that parsed value can then flow unchanged into `build_application_async_logger(...)`, `build_application_text_async_logger(...)`, `build_library_async_logger(...)`, or `build_library_async_text_logger(...)`.
- Because of that, the exported structure is descriptive config data rather than a commitment to one public async type. The later builder or facade API still decides whether the runtime-sink line or the text-console line is taken.

### How to Use

Here are some specific examples provided.

#### When Need Structured Export Of Full Async Setup

When a tool or test needs one object describing the whole async logger build:
```moonbit
let payload = async_logger_build_config_to_json(
  AsyncLoggerBuildConfig::new(
    logger=@bitlogger.LoggerConfig::new(target="svc"),
    async_config=AsyncLoggerConfig::new(max_pending=64),
  ),
)
```

In this example, both layers of configuration are exported together.

And later consumers can still choose whether to rebuild through `build_async_logger(...)` or the narrower `build_async_text_logger(...)` path.

And that later text-specific builder choice still matters more than the serialized `logger.sink.kind` value, because only the formatter-backed text path is consumed there.

And the same exported object can just as well be parsed and then routed into the application or library facade builders when the next consumer wants a narrower public async type.

#### When Need Roundtrip-friendly Build Config Data

When generated build config should later be parsed again:
```moonbit
let value = async_logger_build_config_to_json(AsyncLoggerBuildConfig::new())
```

In this example, the resulting JSON matches the supported async build config shape.

### Error Case

e.g.:
- If callers only need the async runtime section, this API is broader than necessary and `async_logger_config_to_json(...)` should be used instead.

- If callers want direct text output, they should use `stringify_async_logger_build_config(...)` instead.

- Exporting the full `logger` section does not imply that every async builder will later consume every logger field equally.

- Exporting `logger.sink.kind="file"` or `"console"` also does not force the later text-specific builder path to branch that way; only `build_async_logger(...)` follows sink kind when constructing the runtime sink.

- Choosing an application or library facade builder later does not change the meaning of the exported config by itself; those facade APIs inherit the same runtime-sink-versus-text-console split from the direct builder they delegate to.

### Notes

1. Use this helper when tools or tests need a structured JSON object instead of text.

2. Use `stringify_async_logger_build_config(...)` when the same build shape should be emitted as JSON text directly.

3. The resulting object round-trips through `parse_async_logger_build_config_text(...)`, even though different async builders later consume different parts of the embedded `LoggerConfig`.

4. After parsing, that same object can also feed the application or library facade builders; export preserves one shared build-config shape, not a direct-builder-only route.

