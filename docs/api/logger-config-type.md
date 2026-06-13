---
name: logger-config-type
group: api
category: config
update-time: 20260613
description: Public logger config alias used for serializable top-level sync logger settings.
key-word:
    - logger
    - config
    - alias
    - public
---

## Logger-config-type

`LoggerConfig` is the public top-level serializable config type used to describe sync logger behavior. It is a direct alias to the logger config model used by config parsers, sync logger builders, and async build config embedding.

### Interface

```moonbit
pub type LoggerConfig = @utils.LoggerConfig
```

#### output

- `LoggerConfig` - Public logger config object containing `min_level`, `target`, `timestamp`, `sink`, and optional `queue`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a built logger instance.
- The current fields are `min_level : Level`, `target : String`, `timestamp : Bool`, `sink : SinkConfig`, and `queue : QueueConfig?`.
- `LoggerConfig::new(...)` constructs this type as the main sync config entry point.
- `parse_logger_config_text(...)`, `logger_config_to_json(...)`, `stringify_logger_config(...)`, and `build_logger(...)` all consume or produce the same public config shape.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Top-level Logger Policy

When sync logger settings should remain structured config data before runtime construction:
```moonbit
let config : LoggerConfig = LoggerConfig::new(target="svc")
```

In this example, the logger setup stays as a typed config object instead of becoming a runtime logger immediately.

#### When Need To Inspect Or Export Full Sync Logger Settings

When configuration should be reviewed or serialized before build time:
```moonbit
let config = LoggerConfig::new(queue=Some(QueueConfig::new(16)))
println(stringify_logger_config(config, pretty=true))
```

In this example, the same public config type supports both inspection and later runtime assembly.

### Error Case

e.g.:
- `LoggerConfig` itself does not have a runtime failure mode.

- A valid config object can still describe a sink shape whose eventual runtime behavior depends on backend support, such as file output on limited targets.

### Notes

1. Use `LoggerConfig::new(...)` when you need a value of this type in code.

2. Use `ConfiguredLogger` or `Logger` only after a build step when runtime logging behavior is actually needed.
