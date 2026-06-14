---
name: async-logger-config
group: api
category: async
update-time: 20260614
description: Create the async queue, batching, linger, and flush policy config used by async loggers.
key-word:
    - async
    - config
    - queue
    - public
---

## Async-logger-config

Create an `AsyncLoggerConfig` value describing queue capacity, overflow behavior, batching size, linger timing, and flush policy for async logger construction.

### Interface

```moonbit
pub fn AsyncLoggerConfig::new(
  max_pending~ : Int = 0,
  overflow~ : AsyncOverflowPolicy = AsyncOverflowPolicy::Blocking,
  max_batch~ : Int = 1,
  linger_ms~ : Int = 0,
  flush~ : AsyncFlushPolicy = AsyncFlushPolicy::Never,
) -> AsyncLoggerConfig {}
```

#### input

- `max_pending : Int` - Requested maximum queued records before overflow policy matters; negative values are preserved in the config object and later treated as `0` by runtime queue creation.
- `overflow : AsyncOverflowPolicy` - Queue overflow strategy.
- `max_batch : Int` - Maximum records drained per batch.
- `linger_ms : Int` - Optional wait window for batch accumulation.
- `flush : AsyncFlushPolicy` - Flush behavior for batch/shutdown phases.

#### output

- `AsyncLoggerConfig` - Async runtime config object used by `async_logger(...)` or async build helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- `max_batch <= 1` is normalized to `1`.
- `linger_ms < 0` is normalized to `0`.
- `max_pending` is stored as provided by the constructor.
- When the async logger runtime later builds its internal queue, negative `max_pending` is interpreted as `0`.
- `overflow` and `flush` define the most important queue/runtime behavior tradeoffs.
- This type is used directly by `async_logger(...)` and embedded in `AsyncLoggerBuildConfig`.

### How to Use

Here are some specific examples provided.

#### When Tune Async Queue Backlog And Batch Size

When async behavior should be explicit in code:
```moonbit
let config = AsyncLoggerConfig::new(
  max_pending=128,
  overflow=AsyncOverflowPolicy::DropOldest,
  max_batch=8,
  linger_ms=10,
  flush=AsyncFlushPolicy::Batch,
)
```

In this example, queue pressure, batch size, and flush timing are configured together.

#### When Export Async Config

When async policy should be serialized or logged:
```moonbit
println(stringify_async_logger_config(AsyncLoggerConfig::new(max_pending=8)))
```

In this example, the config becomes a stable JSON payload.

### Error Case

e.g.:
- If `max_batch` is set to `0` or below, constructor normalization changes it to `1`.

- If `linger_ms` is negative, constructor normalization changes it to `0`.

### Notes

1. This type controls async runtime behavior, not synchronous queue wrapping.

2. Prefer explicit values for production services so overflow and flush semantics are visible.

3. If queue limit semantics for negative values matter, document that behavior explicitly in calling code because the config object preserves the negative value while the runtime queue later clamps it to `0`.
