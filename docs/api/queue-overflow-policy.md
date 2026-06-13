---
name: queue-overflow-policy
group: api
category: sink
update-time: 20260613
description: Public overflow policy alias used by synchronous queued sinks and queue config.
key-word:
    - queue
    - overflow
    - alias
    - public
---

## Queue-overflow-policy

`QueueOverflowPolicy` is the public enum that defines what a synchronous queue should do when it reaches `max_pending`. It is a direct alias to the queue model enum used by both `QueuedSink` and `QueueConfig`.

### Interface

```moonbit
pub type QueueOverflowPolicy = @utils.QueueOverflowPolicy
```

#### output

- `QueueOverflowPolicy` - Public synchronous queue overflow enum with the variants `DropNewest` and `DropOldest`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a separate policy wrapper.
- `QueueOverflowPolicy::DropNewest` keeps the existing queued records and drops the incoming one when the queue is full.
- `QueueOverflowPolicy::DropOldest` removes one pending record and enqueues the new record instead.
- The same enum is used by code-side queue composition through `queued_sink(...)` and config-driven queue composition through `QueueConfig::new(...)`.

### How to Use

Here are some specific examples provided.

#### When Need A Bounded Queue That Prefers Older Pending Records

When the oldest pending records should be preserved and new bursts can be dropped:
```moonbit
let sink = queued_sink(console_sink(), max_pending=32, overflow=QueueOverflowPolicy::DropNewest)
```

In this example, new records are discarded once the queue is full.

#### When Need To Prefer Fresh Records Over Old Pending Work

When backlog should make room for newer records:
```moonbit
let queue = QueueConfig::new(32, overflow=QueueOverflowPolicy::DropOldest)
```

In this example, the oldest pending record is removed when the queue overflows.

### Error Case

e.g.:
- If a queue is unbounded or never reaches capacity, the overflow policy has no effect.

- If parsed JSON uses unsupported overflow text, config parsing raises `ConfigError`.

### Notes

1. This policy belongs to synchronous queue wrappers, not `bitlogger_async`.

2. Use `AsyncOverflowPolicy` for the async logger queue behavior.
