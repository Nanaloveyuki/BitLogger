---
name: async-logger-state-new
group: api
category: async
update-time: 20260707
description: Construct an AsyncLoggerState snapshot from explicit runtime, lifecycle phase, queue, failure text, and flush-policy values without probing a live logger.
key-word:
    - async
    - logger
    - state
    - public
---

## Async-logger-state-new

Construct an `AsyncLoggerState` snapshot from explicit runtime, queue, lifecycle, and failure values. This is the low-level constructor behind the public async logger state shape used in diagnostics.

### Interface

```moonbit
pub fn AsyncLoggerState::new(
  runtime : AsyncRuntimeState,
  phase : AsyncLifecyclePhase,
  pending_count : Int,
  dropped_count : Int,
  last_error : String,
  flush_policy : AsyncFlushPolicy,
) -> AsyncLoggerState {
```

#### input

- `runtime : AsyncRuntimeState` - Embedded backend-level runtime snapshot.
- `phase : AsyncLifecyclePhase` - Primary lifecycle conclusion for the snapshot.
- `pending_count : Int` - Current async queue backlog.
- `dropped_count : Int` - Current dropped-record count.
- `last_error : String` - Latest error text, or an empty string when no failure has been recorded.
- `flush_policy : AsyncFlushPolicy` - Active async flush policy for the logger.

#### output

- `AsyncLoggerState` - Full async logger snapshot containing the supplied runtime, queue, lifecycle, and failure values.

### Explanation

Detailed rules explaining key parameters and behaviors

- This constructor packages the supplied runtime, phase, counters, last error, and flush policy into one public snapshot value.
- It does not inspect a live logger instance by itself.
- `AsyncLogger::state()` is the higher-level API that reads these values from a concrete logger.
- It also does not validate whether the supplied fields represent a combination that could come from one real logger instant.
- The supplied `runtime : AsyncRuntimeState` is stored exactly as provided; this constructor does not recompute `mode` or `background_worker` from the active backend.
- The constructor derives `is_closed`, `is_running`, `has_failed`, `backlog_retained`, `can_rerun`, and `terminal` from the supplied `phase` and `pending_count`.
- The constructed value matches the same public shape used by async logger serializers.
- Because `AsyncLoggerState` is only a data snapshot type, this constructor is mainly useful for tests, adapters, and synthetic diagnostics rather than ordinary logger inspection.
- Serialization helpers accept any `AsyncLoggerState` value, including hand-built ones from this constructor.
- That includes combinations such as `has_failed=true` together with non-zero `pending_count` or a retained `last_error`, and even a manually chosen runtime snapshot that does not match the current backend, all of which are valid for diagnostic snapshots and test fixtures.

### How to Use

Here are some specific examples provided.

#### When Need A Hand-built Async Logger Snapshot

When tests or adapters should construct a full async logger state explicitly:
```moonbit
let state = AsyncLoggerState::new(
  runtime=AsyncRuntimeState::new(AsyncRuntimeMode::Compatibility, false),
  phase=AsyncLifecyclePhase::Running,
  pending_count=0,
  dropped_count=0,
  last_error="",
  flush_policy=AsyncFlushPolicy::Never,
)
```

In this example, a complete async logger snapshot is assembled directly without querying a live logger instance.

#### When Need Structured Diagnostics Input Before Serialization

When code should prepare a typed logger state value for later export:
```moonbit
let state = AsyncLoggerState::new(
  runtime=async_runtime_state(),
  phase=logger.phase(),
  pending_count=logger.pending_count(),
  dropped_count=logger.dropped_count(),
  last_error=logger.last_error(),
  flush_policy=logger.flush_policy(),
)
```

In this example, callers still use the direct constructor while making each diagnostic input explicit.

### Error Case

e.g.:
- This constructor itself does not have a normal failure mode; it only packages the provided values.

- If callers want a snapshot directly from one live logger instance, `AsyncLogger::state()` is the simpler API.

- If callers manually combine a runtime snapshot, counters, or flush policy that do not actually belong together, the constructor still accepts that synthetic snapshot.

- If callers want the current backend-derived runtime pair instead of a synthetic one, they must pass `async_runtime_state()` explicitly or use `AsyncLogger::state()`.

- This constructor does not apply cleanup semantics such as clearing `last_error` on restart or draining pending records; callers must provide the phase and counters exactly as they want them represented.

### Notes

1. Use this helper when code should construct an `AsyncLoggerState` value explicitly.

2. Pair it with `async_logger_state_to_json(...)` or `stringify_async_logger_state(...)` when the snapshot should be exported.

3. Prefer `AsyncLogger::state()` when the goal is to report the actual current state of one live logger instance.
