# Queueing And Overflow

Use a queue when a short burst of log writes should not immediately reach the output sink. Queueing is explicit because loss behavior is an application decision.

## Add A Synchronous Queue

```moonbit
let config = @log.with_queue(
  @log.text_console(target="service"),
  max_pending=128,
  overflow=@log.QueueOverflowPolicy::DropOldest,
)
let logger = @log.build_logger(config)

logger.info("queued record")
ignore(logger.flush())
```

`DropOldest` preserves the newest operational information when the queue is full. Use `DropNewest` when preserving earlier records matters more. Calling `flush()` at a shutdown boundary makes the pending-record policy visible in application code.

## When To Use Async Instead

The synchronous queue is configuration around a normal runtime logger. When a native async application needs a worker lifecycle and batching, follow [Async logger lifecycle](../examples/async.md) instead.

## API Reference

- [`with_queue(...)`](../api/with-queue.md)
- [`QueueConfig`](../api/queue-config.md)
- [`QueueOverflowPolicy`](../api/queue-overflow-policy.md)
- [`flush()`](../api/configured-logger-flush.md)
