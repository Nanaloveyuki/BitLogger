---
name: logger-with-queue
group: api
category: logging
update-time: 20260512
description: Wrap a synchronous logger with an explicit bounded queue and overflow policy.
key-word:
    - logger
    - queue
    - buffering
    - public
---

## Logger-with-queue

Wrap a logger with a `QueuedSink[S]` so records are first stored in an explicit queue and later drained to the wrapped sink. This API is useful when you want bounded backlog behavior without introducing the async runtime adapter package.

### Interface

```moonbit
pub fn[S] Logger::with_queue(
  self : Logger[S],
  max_pending~ : Int = 0,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> Logger[QueuedSink[S]] {}
```

#### input

- `self : Logger[S]` - Base logger to wrap.
- `max_pending : Int` - Maximum queued records before overflow behavior is applied.
- `overflow : QueueOverflowPolicy` - Queue overflow strategy such as `DropNewest` or `DropOldest`.

#### output

- `Logger[QueuedSink[S]]` - A logger using an explicit synchronous queue wrapper.

### Explanation

Detailed rules explaining key parameters and behaviors

- This queue wrapper is synchronous and explicit. It is not the same as `bitlogger_async` runtime scheduling.
- Callers can inspect `pending_count()` and `dropped_count()` through the wrapped sink.
- `flush()` or `drain(...)` is required to move queued data to the underlying sink.
- Overflow policy determines whether new or old records are discarded when the queue is full.

### How to Use

Here are some specific examples provided.

#### When Need Explicit Manual Drain

When records should accumulate and flush at controlled points:
```moonbit
let logger = Logger::new(console_sink(), target="queue")
  .with_queue(max_pending=2, overflow=QueueOverflowPolicy::DropOldest)

logger.info("one")
logger.info("two")
ignore(logger.sink.flush())
```

In this example, records stay queued until explicitly flushed.

And backlog size stays bounded.

#### When Need Bounded Overload Behavior

When you need defined behavior under burst load:
```moonbit
let logger = Logger::new(console_sink())
  .with_queue(max_pending=100, overflow=QueueOverflowPolicy::DropNewest)
```

In this example, queue pressure is limited instead of growing without bound.

### Error Case

e.g.:
- If `max_pending` is too small, records may be dropped frequently under bursts.

- If callers never flush or drain the queue, queued records remain pending and do not reach the sink.

### Notes

Notes are here.

1. Use this API when you want explicit bounded buffering without `bitlogger_async`.

2. `with_queue(...)` preserves the normal synchronous logger call style.

3. Always define when and where the queue will be drained.

4. For background queue draining, prefer `bitlogger_async` instead.
