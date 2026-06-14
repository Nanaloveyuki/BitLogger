---
name: async-logger-close
group: api
category: async
update-time: 20260614
description: Close the async logger queue immediately and optionally convert current pending backlog into dropped records before queue closure.
key-word:
    - async
    - logger
    - lifecycle
    - public
---

## Async-logger-close

Close the async logger queue and stop treating the logger as an active enqueue target. This API is the low-level lifecycle close primitive behind shutdown flows.

### Interface

```moonbit
pub fn[S] AsyncLogger::close(self : AsyncLogger[S], clear? : Bool = false) -> Unit {}
```

#### input

- `self : AsyncLogger[S]` - Async logger that should be closed.
- `clear : Bool` - Whether pending records should be abandoned immediately instead of being left for drain behavior.

#### output

- `Unit` - No return value. The logger lifecycle state is updated in place.

### Explanation

Detailed rules explaining key parameters and behaviors

- `close(...)` marks the logger as closed immediately.
- `clear=false` closes the queue without explicitly abandoning pending records in the helper itself.
- `clear=true` counts pending records as dropped and resets `pending_count` to `0` before closing the queue.
- This helper does not itself wait for the worker to finish.
- `close(...)` also does not change `has_failed()` or `last_error()`; it is a closure primitive, not a failure reset API.
- Because this is a low-level close primitive, it does not first run `wait_idle()` or apply the runtime-dependent fallback logic used by `shutdown()`.
- After closure, later log attempts do not add new pending or dropped counts, but backend behavior can still differ before the closed queue rejects the record.
- In the current direct coverage, compatibility runtimes short-circuit before patch-path work on late log attempts, while native-worker runtimes may still build and patch the record before the closed queue rejects it.

### How to Use

Here are some specific examples provided.

#### When Need Immediate Queue Closure

When teardown should stop normal enqueue activity right away:
```moonbit
logger.close()
```

In this example, the logger enters closed state immediately.

#### When Need To Abandon Backlog Explicitly

When pending records should be discarded during fast shutdown:
```moonbit
logger.close(clear=true)
```

In this example, queued backlog is counted as dropped instead of waiting for further drain.

### Error Case

e.g.:
- If `clear=true`, pending records are intentionally discarded and contribute to `dropped_count()`.

- If `clear=false`, pending records may still exist after closure until worker drain or later cleanup resolves them.

- If callers perform late log attempts after closure, backlog counters still stay unchanged, but patch-path side effects are runtime-dependent and should not be treated as a portable post-close contract.

- If callers need graceful waiting for drain completion, `shutdown()` is usually the better API.

### Notes

1. This is a low-level lifecycle helper; prefer `shutdown()` for normal graceful teardown.

2. Use `clear=true` only when backlog loss is an acceptable shutdown tradeoff.

3. Pair it with `pending_count()`, `dropped_count()`, or `state()` when you need to observe what happened to existing backlog after closure.
