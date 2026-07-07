---
name: queue-config-type
group: api
category: config
update-time: 20260707
description: Public queue config type re-exported from config_model for serializable sync queue settings.
key-word:
    - queue
    - config
    - alias
    - public
---

## Queue-config-type

`QueueConfig` is the public serializable config type used to describe synchronous queue wrapping. On the root `src` facade, it is re-exported from `src/config_model`, which is the real owner of the concrete queue config model.

### Interface

```moonbit
pub using @config_model { type QueueConfig }
```

#### output

- `QueueConfig` - Public queue config object containing `max_pending` and `overflow`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This root surface is a re-export, not the concrete owner definition.
- The concrete type lives in `@config_model.QueueConfig`, not in `@utils`.
- The current fields are `max_pending : Int` and `overflow : QueueOverflowPolicy`.
- `QueueConfig::new(...)` constructs this type as the normal handwritten entry point.
- `queue_config_to_json(...)` and `stringify_queue_config(...)` serialize the same public config shape for tooling or persistence.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Queue Policy Value

When synchronous queue behavior should be carried as config instead of attached immediately to a logger:
```moonbit
let queue : QueueConfig = QueueConfig::new(32, overflow=QueueOverflowPolicy::DropOldest)
```

In this example, the queue policy stays as one typed value that can be embedded into larger config objects later.

#### When Need To Inspect Or Export Queue Settings

When queue wrapping policy should be serialized or logged before build time:
```moonbit
let queue = QueueConfig::new(8)
println(stringify_queue_config(queue, pretty=true))
```

In this example, the same public config type supports both inspection and later runtime assembly.

### Error Case

e.g.:
- `QueueConfig` itself does not have a runtime failure mode.

- If queue config is never attached to a `LoggerConfig`, it remains valid data but has no effect on built runtime loggers.

### Notes

1. Use `QueueConfig::new(...)` when you need a value of this type in code.

2. Use `QueuedSink` or `Logger::with_queue(...)` when you need direct runtime queue composition instead of config data.
