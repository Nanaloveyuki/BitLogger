---
name: async-overflow-policy
group: api
category: async
update-time: 20260614
description: Public overflow policy alias used by AsyncLoggerConfig, async parser labels, and runtime queue behavior.
key-word:
    - async
    - overflow
    - alias
    - public
---

## Async-overflow-policy

`AsyncOverflowPolicy` is the public enum that controls what an `AsyncLogger` should do when its queue cannot accept a record immediately. It is a direct alias to the async model enum used by `AsyncLoggerConfig` and the runtime queue selection logic.

### Interface

```moonbit
pub type AsyncOverflowPolicy = @utils.AsyncOverflowPolicy
```

#### output

- `AsyncOverflowPolicy` - Public async queue overflow enum with the variants `Blocking`, `DropOldest`, and `DropNewest`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a separate runtime adapter.
- `AsyncOverflowPolicy::Blocking` waits for queue space when a non-blocking enqueue does not succeed.
- `AsyncOverflowPolicy::DropOldest` lets the underlying async queue discard older pending records when capacity is limited.
- `AsyncOverflowPolicy::DropNewest` discards the incoming record instead of blocking.
- The same enum is used by `AsyncLoggerConfig::new(...)`, async config parsing, and the queue-kind mapping inside `AsyncLogger`.
- The canonical labels `Blocking`, `DropOldest`, and `DropNewest` are also the labels emitted again by async config serializers, so export and parse stay aligned around one public vocabulary.
- Async config parsing accepts the canonical label `DropNewest` and also the compatibility alias `DropLatest`, both mapping to the same public enum variant.
- When `try_put(...)` reports that a record was not accepted under a drop policy, `dropped_count()` increases for that rejected enqueue.

### How to Use

Here are some specific examples provided.

#### When Need Backpressure Instead Of Silent Dropping

When producers should wait for queue space:
```moonbit
let config = AsyncLoggerConfig::new(max_pending=64, overflow=AsyncOverflowPolicy::Blocking)
```

In this example, logging pressure can slow producers instead of dropping data immediately.

#### When Need Bounded Async Logging With Drop Behavior

When async logging should keep moving under load without blocking callers:
```moonbit
let config = AsyncLoggerConfig::new(max_pending=64, overflow=AsyncOverflowPolicy::DropNewest)
```

In this example, the incoming record is dropped if the queue cannot accept it.

### Error Case

e.g.:
- If async config text uses unsupported overflow text, async config parsing raises a failure.

- The parser error path for unsupported overflow text is the same `Failure` surface used by the async config utilities.

- Under drop policies, sustained overload increases `dropped_count()` instead of guaranteeing delivery.

- The precise record discarded by the underlying queue behavior depends on the selected policy and queue implementation, so callers should not assume `dropped_count()` alone identifies which message was lost.

### Notes

1. This policy applies to `bitlogger_async`, not synchronous `QueuedSink`.

2. Choose `Blocking` only when producer-side waiting is acceptable for the caller.

3. Serialized config uses the canonical `DropNewest` label even though the parser also accepts `DropLatest`.
