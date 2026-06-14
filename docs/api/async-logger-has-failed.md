---
name: async-logger-has-failed
group: api
category: async
update-time: 20260614
description: Read whether the async logger worker has recorded a runtime failure after run() startup reset and drain execution.
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
- `run()` also clears the stored `last_error()` string at startup before drain work begins.
- If the worker loop raises an error, the logger records that failure and exposes it through this flag.
- Once set by a failed run, the flag stays `true` until a later `run()` invocation actually starts and resets it.
- Failure-driven shutdown does not clear this flag by itself, so `has_failed()` can remain `true` even after the logger is already closed.
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

- If `has_failed()` becomes `true`, `wait_idle()` may stop early while pending records still remain until a later close or clear path handles them.
- In the current regression coverage, that later handling can be an explicit `close(clear=true)` that resets pending backlog immediately or a runtime-dependent `shutdown(...)` path that either clears pending into dropped records or leaves the closed-queue remainder visible.

- If `has_failed()` is still `true` after shutdown, that does not by itself mean cleanup failed; the logger may already be `is_closed=true` while the remaining pending-versus-dropped outcome still reflects the active runtime's shutdown path.

- If `has_failed()` is `true`, callers should inspect `last_error()` or `state()` for more context.

- `close()` or `shutdown()` do not clear this flag by themselves; only a later `run()` that has already started resets it.

### Notes

1. This helper reports worker failure, not general queue stress.

2. Pair it with `last_error()` when you need actionable detail.

3. Pair it with `is_running()` or `state()` when you also need to know whether the worker has already exited and whether backlog remains.
