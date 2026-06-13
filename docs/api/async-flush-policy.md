---
name: async-flush-policy
group: api
category: async
update-time: 20260613
description: Public flush policy alias used by AsyncLoggerConfig and async worker flushing.
key-word:
    - async
    - flush
    - alias
    - public
---

## Async-flush-policy

`AsyncFlushPolicy` is the public enum that defines when an async logger should call its flush function. It is a direct alias to the async model enum used by `AsyncLoggerConfig`, worker execution, and async logger state reporting.

### Interface

```moonbit
pub type AsyncFlushPolicy = @utils.AsyncFlushPolicy
```

#### output

- `AsyncFlushPolicy` - Public async flush enum with the variants `Never`, `Batch`, and `Shutdown`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a separate lifecycle wrapper.
- `AsyncFlushPolicy::Never` skips explicit flush calls from the async worker.
- `AsyncFlushPolicy::Batch` calls the configured flush function after each processed batch.
- `AsyncFlushPolicy::Shutdown` calls the configured flush function once after the worker loop exits.
- The current flush policy is also exposed through `AsyncLogger::flush_policy()` and included in `AsyncLoggerState`.

### How to Use

Here are some specific examples provided.

#### When Need Explicit Flush After Every Processed Batch

When buffered sinks should flush incrementally during worker execution:
```moonbit
let config = AsyncLoggerConfig::new(flush=AsyncFlushPolicy::Batch)
```

In this example, each batch run triggers the provided flush callback.

#### When Need One Final Flush During Shutdown

When sink flushing should be deferred until the worker finishes:
```moonbit
let config = AsyncLoggerConfig::new(flush=AsyncFlushPolicy::Shutdown)
```

In this example, flushing happens when the worker loop exits instead of after each batch.

### Error Case

e.g.:
- If async config text uses unsupported flush policy text, async config parsing raises a failure.

- If a sink never needs explicit flushing, `Batch` or `Shutdown` can add unnecessary work without changing output.

### Notes

1. This policy only affects the async logger path and only matters when the configured sink has a meaningful flush function.

2. `AsyncFlushPolicy::Never` is the default in `AsyncLoggerConfig::new(...)`.
