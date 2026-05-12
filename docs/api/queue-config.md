---
name: queue-config
group: api
category: config
update-time: 20260512
description: Create a serializable queue wrapper config for configured synchronous loggers.
key-word:
    - queue
    - config
    - json
    - public
---

## Queue-config

Create a `QueueConfig` value for config-driven synchronous queue wrapping. This API is used inside `LoggerConfig` when the final runtime sink should be wrapped by a bounded synchronous queue.

### Interface

```moonbit
pub fn QueueConfig::new(
  max_pending : Int,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueueConfig {}
```

#### input

- `max_pending : Int` - Queue capacity used by the configured queue wrapper.
- `overflow : QueueOverflowPolicy` - Overflow strategy for full queues.

#### output

- `QueueConfig` - Queue configuration value suitable for `LoggerConfig` or JSON serialization helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- This config is used by `build_logger(...)` and `parse_and_build_logger(...)` when `queue` is present in `LoggerConfig`.
- It configures the synchronous `QueuedSink`, not the async adapter package.
- The queue remains explicit and drain-based.
- Overflow behavior is limited to the supported queue policies.

### How to Use

Here are some specific examples provided.

#### When Need Config-driven Bounded Queueing

When runtime queue wrapping should be described as config:
```moonbit
let queue = QueueConfig::new(32, overflow=QueueOverflowPolicy::DropOldest)
let config = LoggerConfig::new(queue=Some(queue))
```

In this example, the queue policy is expressed as data and later consumed by the runtime builder.

#### When Need JSON Export For Tooling

When queue policy should be exported or persisted:
```moonbit
println(stringify_queue_config(QueueConfig::new(8)))
```

In this example, the queue config is converted into a stable JSON representation.

### Error Case

e.g.:
- If `max_pending` is too small, configured runtime drops may happen frequently under bursty load.

- If queue config is omitted from `LoggerConfig`, no synchronous queue wrapper is added.

### Notes

1. This API is for config-driven queue wrapping, not `bitlogger_async`.

2. Use `Logger::with_queue(...)` when you want code-side queue composition instead of config.
