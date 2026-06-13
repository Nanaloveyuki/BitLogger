---
name: async-flush-policy
group: api
category: async
update-time: 20260614
description: Public flush policy alias used by AsyncLoggerConfig, async parser labels, and async worker flushing.
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
- The canonical labels `Never`, `Batch`, and `Shutdown` are also the labels emitted by async config and logger-state serializers, so parsing and diagnostics share one public vocabulary.
- Async config parsing accepts the canonical label `Never` and also the compatibility alias `None`, both mapping to the same public enum variant.
- `Batch` flushing happens after the worker finishes one drained batch, not after every individual record write.

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

- The parser error path for unsupported flush text is the same `Failure` surface used by the async config utilities.

- If a sink never needs explicit flushing, `Batch` or `Shutdown` can add unnecessary work without changing output.

- If the configured flush callback raises, the worker records failure state and stops instead of silently hiding the error.

### Notes

1. This policy only affects the async logger path and only matters when the configured sink has a meaningful flush function.

2. `AsyncFlushPolicy::Never` is the default in `AsyncLoggerConfig::new(...)`.

3. Serialized config uses the canonical `Never` label even though the parser also accepts `None`.
