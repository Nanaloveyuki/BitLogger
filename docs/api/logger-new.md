---
name: logger-new
group: api
category: logging
update-time: 20260512
description: Create a typed logger with level filtering, target binding, and optional later composition.
key-word:
    - logger
    - sync
    - public
    - target
---

## Logger-new

Create a `Logger[S]` from any sink implementation. This is the main entry for synchronous logging pipelines and the base object used by most chainable helpers such as `with_context_fields(...)`, `with_filter(...)`, `with_patch(...)`, and `with_queue(...)`.

### Interface

```moonbit
pub fn[S] Logger::new(sink : S, min_level~ : Level = Level::Info, target~ : String = "") -> Logger[S] {}
```

#### input

- `sink : S` - Any sink value implementing the `Sink` trait, such as `console_sink()`, `json_console_sink()`, `file_sink(...)`, or a composed sink.
- `min_level : Level` - Minimum enabled level. Messages below this threshold are ignored.
- `target : String` - Default target attached to emitted records when `log(...)` does not override it.

#### output

- `Logger[S]` - A typed logger that keeps the original sink type and can be further composed.

### Explanation

Detailed rules explaining key parameters and behaviors

- `Logger::new(...)` does not mutate the sink. It stores the sink value as part of the returned logger.
- `min_level` applies before any sink write occurs.
- `target` is just a default value. Later calls may override it with `with_target(...)`, `child(...)`, or `log(..., target=...)`.
- `timestamp` is disabled by default and is only enabled through `with_timestamp()`.

### How to Use

Here are some specific examples provided.

#### When Create Basic Application Logger

When you need a simple typed logger with a default target:
```moonbit
let logger = Logger::new(console_sink(), min_level=Level::Info, target="app")
logger.info("started")
```

In this example, `logger` will emit `INFO` and above to the console with target `app`.

And later composition still preserves the typed logger workflow.

#### When Start A Composed Logging Pipeline

When you want to build a richer logging chain from a single root logger:
```moonbit
let logger = Logger::new(text_console_sink(text_formatter()), target="service")
  .with_timestamp()
  .with_context_fields([field("service", "billing")])
```

In this example, the root logger becomes the stable base for additional context and formatting features.

### Error Case

e.g.:
- If `min_level` is set too high, lower-severity records are intentionally dropped.

- If `target` is empty, records are still valid and simply omit the target unless later overridden.

### Notes

Notes are here.

1. This API is synchronous and does not create buffering or background execution by itself.

2. The returned sink type stays visible in `Logger[S]`, which is useful for typed composition.

3. Prefer `Logger::new(...)` over global helpers when you want explicit control over sink, target, and level.

4. `Logger::new(...)` is the correct starting point for both public app logging and internal composed sink pipelines.
