---
name: json-console
group: api
category: config
update-time: 20260520
description: Create a logger config preset for the built-in JSON console sink.
key-word:
    - preset
    - json
    - console
    - public
---

## Json-console

Create a `LoggerConfig` preset for structured JSON output on the console. This preset is intended for config-driven logging pipelines that want machine-readable terminal output.

### Interface

```moonbit
pub fn json_console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
) -> LoggerConfig {
```

#### input

- `min_level : Level` - Minimum enabled level for the preset.
- `target : String` - Default target stored in the returned config.
- `timestamp : Bool` - Whether emitted records should include timestamps.

#### output

- `LoggerConfig` - Config using `SinkKind::JsonConsole` with no queue wrapper by default.

### Explanation

Detailed rules explaining key parameters and behaviors

- This preset always returns `sink.kind=SinkKind::JsonConsole`.
- `queue=None` by default, so JSON records are not buffered unless `with_queue(...)` is added later.
- The preset does not carry file-only fields such as `path` or `rotation` in a meaningful way because the sink kind is not file-based.

### How to Use

Here are some specific examples provided.

#### When Need Structured Console Output

When logs should be easy to collect or parse from stdout:
```moonbit
let config = json_console(min_level=Level::Info, target="api", timestamp=true)
let logger = build_logger(config)
```

In this example, records are emitted through the JSON console sink.

And timestamps are enabled at the top-level logger config.

### Error Case

e.g.:
- If `target` is empty, the preset still returns a valid config.

- If you need file rotation or file paths, this preset is the wrong sink shape and should be replaced with `file(...)`.

### Notes

1. Use this preset when downstream tooling expects structured console logs.

2. `with_file_rotation(...)` does not change this preset because it only applies to file configs.
