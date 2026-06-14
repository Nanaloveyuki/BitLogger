---
name: logger-with-min-level
group: api
category: logging
update-time: 20260512
description: Replace the logger minimum enabled level so lower-severity records are skipped earlier.
key-word:
    - logger
    - level
    - filter
    - public
---

## Logger-with-min-level

Replace the logger's minimum enabled level. This API controls the first gate checked by `log(...)` and the convenience level methods.

### Interface

```moonbit
pub fn[S] Logger::with_min_level(self : Logger[S], min_level : Level) -> Logger[S] {}
```

#### input

- `self : Logger[S]` - Base logger whose level threshold should change.
- `min_level : Level` - New minimum enabled level.

#### output

- `Logger[S]` - A new logger value carrying the updated threshold.

### Explanation

Detailed rules explaining key parameters and behaviors

- `log(...)` checks `is_enabled(level)` before constructing and writing a record.
- Lower-severity records below `min_level` are skipped without reaching the sink.
- The returned logger is derived from `self`; the original logger value is not mutated.
- This API replaces the stored threshold and does not add a wrapper sink.
- Only `min_level` changes. Sink, target, and timestamp behavior stay on the same `Logger[S]` surface.

### How to Use

Here are some specific examples provided.

#### When Raise Noise Floor In Production

When only warning and error records should be emitted:
```moonbit
let logger = Logger::new(console_sink())
  .with_min_level(Level::Warn)
```

In this example, `trace`, `debug`, and `info` calls are skipped.

The returned logger still uses the same ordinary synchronous logging calls; only the severity gate changes.

#### When Derive A More Verbose Local Logger

When one branch of code should keep a different threshold:
```moonbit
let base = Logger::new(console_sink(), min_level=Level::Info)
let debug_logger = base.with_min_level(Level::Debug)
```

In this example, the sink is reused while the threshold changes per logger value.

### Error Case

e.g.:
- If `min_level` is set too high, expected lower-severity diagnostics may disappear.

- If callers need richer predicate logic than a simple threshold, `with_filter(...)` should be used instead.

### Notes

1. This API skips disabled levels before any sink write happens.

2. Use it before adding more complex predicate-based filtering rules.

3. Use a derived logger value when one branch should tighten the threshold and the base logger should keep its broader level gate.

