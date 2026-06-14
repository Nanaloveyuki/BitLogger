---
name: async-logger-with-min-level
group: api
category: async
update-time: 20260512
description: Replace the async logger minimum enabled level so lower-severity records are skipped before enqueue.
key-word:
    - async
    - logger
    - level
    - public
---

## Async-logger-with-min-level

Replace the async logger's minimum enabled level. This API controls the first gate checked before record creation and queue insertion.

### Interface

```moonbit
pub fn[S] AsyncLogger::with_min_level(
  self : AsyncLogger[S],
  min_level : @bitlogger.Level,
) -> AsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Base async logger whose level threshold should change.
- `min_level : Level` - New minimum enabled level.

#### output

- `AsyncLogger[S]` - A new async logger value carrying the updated threshold.

### Explanation

Detailed rules explaining key parameters and behaviors

- `log(...)` checks `is_enabled(level)` before creating a record or touching the queue.
- Lower-severity records below `min_level` are skipped before enqueue.
- The returned logger is derived from `self`; the original async logger value is not mutated.
- This API replaces the stored threshold and does not alter queue configuration.
- Only `min_level` changes. Sink, target, timestamp flag, and lifecycle/failure state stay on the same `AsyncLogger[S]` surface.
- In the current direct async coverage, the derived logger reports the new threshold through `is_enabled(...)`, while the original logger keeps its previous minimum level and still accepts records that remain enabled there.

### How to Use

Here are some specific examples provided.

#### When Raise Async Noise Floor In Production

When only warning and error records should reach the async queue:
```moonbit
let logger = async_logger(console_sink())
  .with_min_level(@bitlogger.Level::Warn)
```

In this example, lower-severity records are skipped before queue pressure increases.

And the returned async logger still keeps the same queue-facing API surface as the source logger.

#### When Derive A More Verbose Async Branch

When one branch of code should keep a different threshold:
```moonbit
let base = async_logger(console_sink(), min_level=@bitlogger.Level::Info)
let debug_logger = base.with_min_level(@bitlogger.Level::Debug)
```

In this example, the async sink and queue settings are reused while the threshold changes per logger value.

### Error Case

e.g.:
- If `min_level` is set too high, expected lower-severity diagnostics may disappear before they ever enter the queue.

- If callers need richer predicate logic than a simple threshold, `with_filter(...)` should be used instead.

### Notes

1. This API reduces async queue pressure by dropping disabled levels before enqueue.

2. Use it before adding more complex async filtering rules.

3. State helpers such as `pending_count()`, `dropped_count()`, `is_closed()`, and `has_failed()` remain available on the returned logger because the visible async logger surface is preserved.

4. Use a derived logger value when one branch should tighten the threshold and the base async logger should keep its broader level gate.
