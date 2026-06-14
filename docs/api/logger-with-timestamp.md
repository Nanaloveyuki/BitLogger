---
name: logger-with-timestamp
group: api
category: logging
update-time: 20260512
description: Enable or disable automatic timestamp capture for records emitted by a logger.
key-word:
    - logger
    - timestamp
    - record
    - public
---

## Logger-with-timestamp

Enable or disable automatic timestamp capture on log emission. This API controls whether `Logger::log(...)` records the current time through `@env.now()` or leaves the timestamp at `0UL`.

### Interface

```moonbit
pub fn[S] Logger::with_timestamp(self : Logger[S], enabled~ : Bool = true) -> Logger[S] {}
```

#### input

- `self : Logger[S]` - Base logger whose timestamp behavior should change.
- `enabled : Bool` - Whether emitted records should capture current time automatically.

#### output

- `Logger[S]` - A new logger value with updated timestamp behavior.

### Explanation

Detailed rules explaining key parameters and behaviors

- When enabled, `log(...)` captures `@env.now()` and stores it in the record.
- When disabled, emitted records use `0UL` as the timestamp value.
- This setting affects later emitted records only.
- The returned logger is derived from `self`; the original logger value is not mutated.
- Only the stored `timestamp` flag changes. Target, minimum level, and sink behavior stay on the same `Logger[S]` surface.
- Formatter or sink behavior stays unchanged; they just receive records with or without real timestamps.

### How to Use

Here are some specific examples provided.

#### When Need Real Event Time In Records

When downstream formatting or JSON output should include event time:
```moonbit
let logger = Logger::new(console_sink())
  .with_timestamp()
```

In this example, each emitted record captures current time automatically.

The returned logger still uses the same ordinary synchronous logging calls; only record timestamp capture changes.

#### When Need Deterministic Or Minimal Records

When timestamps should be disabled for tests or reduced output:
```moonbit
let logger = Logger::new(console_sink())
  .with_timestamp(enabled=false)
```

In this example, records are emitted without runtime time capture.

### Error Case

e.g.:
- If timestamps are disabled, formatters that expect meaningful time values may show empty or zero-like timestamp output.

- If callers need timestamps only for one record, per-call customization is not provided here and a separate logger value may be clearer.

### Notes

1. This API controls record creation, not formatter display policy.

2. It works well together with text formatters that optionally show timestamps.

3. Use a derived logger value when one path should capture timestamps and another should keep the original deterministic record shape.

