---
name: with-queue
group: api
category: config
update-time: 20260520
description: Add a queue wrapper to an existing logger config preset.
key-word:
    - preset
    - queue
    - config
    - public
---

## With-queue

Add a synchronous queue wrapper to an existing `LoggerConfig`. This preset helper is the config-side counterpart to `Logger::with_queue(...)`, allowing queue behavior to be expressed before the runtime logger is built.

### Interface

```moonbit
pub fn with_queue(
  config : LoggerConfig,
  max_pending~ : Int = 0,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> LoggerConfig {
```

#### input

- `config : LoggerConfig` - Base logger config to wrap.
- `max_pending : Int` - Maximum number of pending records allowed in the queue.
- `overflow : QueueOverflowPolicy` - Overflow behavior such as `DropNewest` or `DropOldest`.

#### output

- `LoggerConfig` - A copy of the input config with `queue=Some(QueueConfig::new(...))`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper preserves the original config's `min_level`, `target`, `timestamp`, and `sink` fields.
- Only the top-level `queue` field is added or replaced.
- The helper can be composed with any preset, including `console(...)`, `json_console(...)`, `text_console(...)`, and `file(...)`.

### How to Use

Here are some specific examples provided.

#### When Need Config-side Queueing

When queue behavior should be configured before calling `build_logger(...)`:
```moonbit
let config = with_queue(
  text_console(target="svc"),
  max_pending=32,
  overflow=QueueOverflowPolicy::DropOldest,
)
```

In this example, the text console preset is wrapped with a bounded queue config.

And sink-specific settings remain unchanged.

### Error Case

e.g.:
- If `max_pending` is too small, burst traffic may trigger overflow handling sooner.

- If the wrapped runtime logger is never flushed or drained, queued records may remain pending depending on how the built sink is used.

### Notes

1. This helper is config composition only; it does not build or run the logger.

2. Queue wrapping can be combined with `with_file_rotation(...)` when the base config is file-based.
