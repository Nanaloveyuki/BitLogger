---
name: queue-config-new
group: api
category: config
update-time: 20260613
description: Construct a QueueConfig value for config-driven synchronous queue wrapping.
key-word:
    - queue
    - config
    - constructor
    - public
---

## Queue-config-new

Construct a `QueueConfig` value for config-driven synchronous queue wrapping. This constructor stores queue capacity and overflow behavior as data for later logger assembly.

### Interface

```moonbit
pub fn QueueConfig::new(
  max_pending : Int,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueueConfig {
```

#### input

- `max_pending : Int` - Queue capacity used by the configured queue wrapper.
- `overflow : QueueOverflowPolicy` - Overflow strategy used when the queue is full.

#### output

- `QueueConfig` - Queue configuration value suitable for `LoggerConfig` or JSON serialization helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- The constructor stores `max_pending` and `overflow` directly without additional normalization.
- This config is used by `build_logger(...)` and `parse_and_build_logger(...)` when `queue` is present in `LoggerConfig`.
- It configures the synchronous `QueuedSink`, not the async adapter package.
- `overflow` defaults to `QueueOverflowPolicy::DropNewest`.

### How to Use

Here are some specific examples provided.

#### When Need Config-driven Bounded Queueing

When runtime queue wrapping should be described as config data:
```moonbit
let queue = QueueConfig::new(32, overflow=QueueOverflowPolicy::DropOldest)
```

In this example, queue capacity and overflow behavior are captured for later runtime assembly.

#### When Embed Queue Config In Logger Config

When queueing should be part of a larger logger configuration object:
```moonbit
let config = LoggerConfig::new(queue=Some(QueueConfig::new(16)))
```

In this example, queue config becomes one component of the top-level logger config.

### Error Case

e.g.:
- If `max_pending` is too small, configured runtime drops may happen frequently under bursty load.

- If queue config is omitted from `LoggerConfig`, no synchronous queue wrapper is added.

### Notes

1. This constructor is for config-driven queue wrapping, not `bitlogger_async`.

2. Use `Logger::with_queue(...)` when queue composition should be done directly in code.
