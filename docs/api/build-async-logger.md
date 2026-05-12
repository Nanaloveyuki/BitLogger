---
name: build-async-logger
group: api
category: async
update-time: 20260512
description: Build an async logger from combined logger and async config without manually wiring the runtime sink.
key-word:
    - async
    - config
    - builder
    - public
---

## Build-async-logger

Build an async logger directly from `AsyncLoggerBuildConfig`. This is the config-driven async entry point that bridges synchronous logger config, sink creation, and async queue setup in one call.

### Interface

```moonbit
pub fn build_async_logger(config : AsyncLoggerBuildConfig) -> AsyncLogger[@bitlogger.RuntimeSink] {}
```

#### input

- `config : AsyncLoggerBuildConfig` - Combined synchronous logger config plus async queue/flush config.

#### output

- `AsyncLogger[RuntimeSink]` - A config-built async logger with runtime sink control preserved.

### Explanation

Detailed rules explaining key parameters and behaviors

- The `logger` section is built through the same config machinery used by synchronous configured loggers.
- The resulting async logger inherits `min_level`, `target`, and timestamp behavior from the built synchronous logger.
- File, queue, and formatter choices all come from config rather than direct code-side sink wiring.
- The returned sink type is `RuntimeSink`, which keeps configured control helpers available where relevant.

### How to Use

Here are some specific examples provided.

#### When Need Fully Config-driven Async Bootstrapping

When your application should build async logging entirely from configuration:
```moonbit
let config = parse_async_logger_build_config_text(raw) catch {
  err => return
}
let logger = build_async_logger(config)
```

In this example, parsing and async runtime wiring are separated cleanly.

And the returned logger can immediately be started with `run()`.

#### When Need Runtime Sink Features After Async Build

When the sink shape is configured but runtime features still matter:
```moonbit
let logger = build_async_logger(config)
println(stringify_async_logger_state(logger.state(), pretty=true))
```

In this example, the built async logger remains introspectable even though construction was config-driven.

### Error Case

e.g.:
- If the config text was invalid, error handling should happen earlier in `parse_async_logger_build_config_text(...)`.

- If the configured sink shape is unsupported for a specific capability, the resulting runtime behavior follows the existing sink/runtime rules rather than inventing a separate builder-only failure model.

### Notes

Notes are here.

1. Prefer this API when applications externalize both sync sink choice and async queue behavior.

2. Use `async_logger(...)` directly when you want explicit code-defined sink wiring.

3. This API is the async counterpart to `build_logger(...)`.

4. The runtime diagnostics surface remains useful after config-built construction.
