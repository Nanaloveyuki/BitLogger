---
name: async-logger-with-filter
group: api
category: async
update-time: 20260512
description: Attach predicate-based filtering to an async logger so only matching records reach the queue.
key-word:
    - async
    - logger
    - filter
    - public
---

## Async-logger-with-filter

Attach a record predicate to an async logger so only matching records are enqueued. This is the main API for async routing-by-predicate without rewriting sink implementations.

### Interface

```moonbit
pub fn[S] AsyncLogger::with_filter(
  self : AsyncLogger[S],
  predicate : (@bitlogger.Record) -> Bool,
) -> AsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Base async logger to constrain.
- `predicate : (Record) -> Bool` - Record predicate that decides whether a record should be enqueued.

#### output

- `AsyncLogger[S]` - A new async logger that only enqueues matching records.

### Explanation

Detailed rules explaining key parameters and behaviors

- Filtering happens after record construction and patch application but before enqueue.
- Existing filter logic is preserved and combined with the new predicate using logical `and`.
- The original async logger is not mutated.
- Filtering avoids unnecessary queue pressure for records that should never be delivered.

### How to Use

Here are some specific examples provided.

#### When Keep Only One Async Target Namespace

When an async logger should only enqueue records from a specific subsystem:
```moonbit
let logger = async_logger(console_sink(), target="service")
  .with_filter(@bitlogger.target_has_prefix("service.api"))
```

In this example, non-matching records are dropped before they reach the async queue.

#### When Combine Several Async Filter Rules

When filtering depends on multiple conditions:
```moonbit
let logger = async_logger(console_sink(), target="api")
  .with_filter(fn(rec) {
    rec.level.enabled(@bitlogger.Level::Warn) && rec.message.contains("timeout")
  })
```

In this example, only warning-or-higher timeout records are enqueued.

### Error Case

e.g.:
- If the predicate always returns `false`, the logger silently drops every record before enqueue.

- If the predicate always returns `true`, the wrapper behaves like a pass-through filter.

### Notes

1. Use this API for selection logic, not record mutation.

2. Async filtering is especially useful when queue capacity should be reserved for high-value records.
