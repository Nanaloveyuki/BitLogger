---
name: console
group: api
category: config
update-time: 20260520
description: Create a minimal logger config preset for the built-in console sink.
key-word:
    - preset
    - console
    - config
    - public
---

## Console

Create a `LoggerConfig` preset for the built-in plain console sink. This helper is the shortest way to assemble a config-driven logger that writes directly to the terminal without text formatter customization.

### Interface

```moonbit
pub fn console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
) -> LoggerConfig {
```

#### input

- `min_level : Level` - Minimum enabled level for the preset.
- `target : String` - Default target stored in the returned config.
- `timestamp : Bool` - Whether the built logger should emit timestamps.

#### output

- `LoggerConfig` - Config using `SinkKind::Console` with no queue wrapper by default.

### Explanation

Detailed rules explaining key parameters and behaviors

- This preset always returns `sink.kind=SinkKind::Console`.
- `queue=None` by default, so output remains unqueued unless `with_queue(...)` is applied later.
- This helper only selects the sink shape and top-level logger config fields; it does not build a runtime logger by itself.

### How to Use

Here are some specific examples provided.

#### When Need A Minimal Terminal Config

When application startup wants a simple console config:
```moonbit
let config = console(min_level=Level::Debug, target="cli")
let logger = build_logger(config)
```

In this example, the logger uses the built-in console sink.

And no extra queue or file policy is configured.

### Error Case

e.g.:
- If `target` is empty, the config is still valid.

- If later runtime assembly targets an environment with sink-specific limitations, those runtime rules still apply outside this preset.

### Notes

1. Use this preset when you want the shortest path to console output.

2. Apply `with_queue(...)` separately if bounded synchronous buffering is needed.
