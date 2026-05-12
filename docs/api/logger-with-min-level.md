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
- This API replaces the logger threshold and does not add a wrapper sink.
- The returned logger keeps the same sink, target, and timestamp settings.

### How to Use

Here are some specific examples provided.

#### When Raise Noise Floor In Production

When only warning and error records should be emitted:
```moonbit
let logger = Logger::new(console_sink())
  .with_min_level(Level::Warn)
```

In this example, `trace`, `debug`, and `info` calls are skipped.

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

1. This API is the cheapest built-in severity gate.

2. Use it before adding more complex filtering rules.

