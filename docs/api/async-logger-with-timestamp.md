---
name: async-logger-with-timestamp
group: api
category: async
update-time: 20260512
description: Enable or disable automatic timestamp capture for records emitted by an async logger.
key-word:
    - async
    - logger
    - timestamp
    - public
---

## Async-logger-with-timestamp

Enable or disable automatic timestamp capture on async log emission. This API controls whether `AsyncLogger::log(...)` records the current time before enqueue or leaves the timestamp at `0UL`.

### Interface

```moonbit
pub fn[S] AsyncLogger::with_timestamp(self : AsyncLogger[S], enabled~ : Bool = true) -> AsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Base async logger whose timestamp behavior should change.
- `enabled : Bool` - Whether emitted records should capture current time automatically.

#### output

- `AsyncLogger[S]` - A new async logger value with updated timestamp behavior.

### Explanation

Detailed rules explaining key parameters and behaviors

- When enabled, `log(...)` captures `@env.now()` before placing the record into the queue.
- When disabled, emitted records use `0UL` as the timestamp value.
- This setting affects later emitted records only.
- Queue, batching, and flush behavior are unchanged.
- In the current direct async coverage, a derived timestamp-enabled logger records non-zero timestamps while the original logger continues emitting `0UL` timestamps when it was left disabled.

### How to Use

Here are some specific examples provided.

#### When Need Real Event Time Before Queueing

When downstream formatting or JSON output should include event time:
```moonbit
let logger = async_logger(console_sink())
  .with_timestamp()
```

In this example, each record captures its timestamp before entering the async queue.

#### When Need Deterministic Async Records

When timestamps should be disabled for tests or reduced output:
```moonbit
let logger = async_logger(console_sink())
  .with_timestamp(enabled=false)
```

In this example, queued records are emitted without runtime time capture.

### Error Case

e.g.:
- If timestamps are disabled, formatters that expect meaningful time values may show empty or zero-like timestamp output.

- If callers need timestamps only for one record, a separate logger value is usually clearer than toggling behavior repeatedly.

### Notes

1. This API controls record creation before enqueue, not formatter display policy.

2. It is useful for tests, deterministic snapshots, and production timing.

3. Use a derived logger value when only one branch should capture timestamps and the base logger should remain deterministic.
