---
name: async-logger-has-failed
group: api
category: async
update-time: 20260512
description: Read whether the async logger worker has encountered a failure during queue drain.
key-word:
    - async
    - logger
    - failure
    - public
---

## Async-logger-has-failed

Read whether the async logger worker has encountered a failure. This helper is a compact health signal for async delivery problems.

### Interface

```moonbit
pub fn[S] AsyncLogger::has_failed(self : AsyncLogger[S]) -> Bool {}
```

#### input

- `self : AsyncLogger[S]` - Async logger whose failure flag should be inspected.

#### output

- `Bool` - Whether the worker has failed.

### Explanation

Detailed rules explaining key parameters and behaviors

- `run()` clears previous failure state at startup.
- If the worker loop raises an error, the logger records that failure and exposes it through this flag.
- This helper is intentionally compact and should usually be paired with `last_error()` for details.
- Failure state is about runtime drain execution, not whether records were dropped due to overflow policy.

### How to Use

Here are some specific examples provided.

#### When Need A Fast Failure Signal

When runtime diagnostics should branch on worker health:
```moonbit
if logger.has_failed() {
  println(logger.last_error())
}
```

In this example, the code checks failure state first, then reads the error detail.

#### When Inspect Async Runtime State In Tests

When a test needs to confirm that drain execution stayed healthy:
```moonbit
ignore(logger.has_failed())
```

In this example, the helper exposes a simple pass-fail runtime indicator.

### Error Case

e.g.:
- If `has_failed()` is `false`, queue pressure or dropped records may still exist for non-failure reasons.

- If `has_failed()` is `true`, callers should inspect `last_error()` or `state()` for more context.

### Notes

1. This helper reports worker failure, not general queue stress.

2. Pair it with `last_error()` when you need actionable detail.
