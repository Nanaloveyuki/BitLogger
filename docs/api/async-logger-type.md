---
name: async-logger-type
group: api
category: async
update-time: 20260614
description: Public asynchronous logger root type used for queue-backed sink-preserving logging pipelines with explicit lifecycle, failure, and flush-callback state.
key-word:
    - async
    - logger
    - type
    - public
---

## Async-logger-type

`AsyncLogger[S]` is the public asynchronous root logger type. It stores a concrete sink type `S` together with queue policy, runtime state counters, and lifecycle flags, then serves as the base value for async composition, worker control, and async write APIs.

### Interface

```moonbit
pub struct AsyncLogger[S] {
  min_level : @bitlogger.Level
  target : String
  timestamp : Bool
  overflow : AsyncOverflowPolicy
  max_batch : Int
  linger_ms : Int
  flush_policy : AsyncFlushPolicy
  sink : S
  flush_sink : (S) -> Int raise
  context_fields : Array[@bitlogger.Field]
  filter : (@bitlogger.Record) -> Bool
  patch : @bitlogger.RecordPatch
  queue : @async.Queue[@bitlogger.Record]
  pending_count : Ref[Int]
  dropped_count : Ref[Int]
  is_closed : Ref[Bool]
  is_running : Ref[Bool]
  has_failed : Ref[Bool]
  last_error : Ref[String]
}
```

#### output

- `AsyncLogger[S]` - Public queue-backed asynchronous logger value parameterized by the concrete sink type `S`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields cover targeting, overflow policy, batching, linger timing, flush policy, the wrapped sink, context/filter/patch behavior, queue state, and worker lifecycle flags.
- `flush_sink : (S) -> Int raise` stores the raising flush callback used by batch and shutdown flush policies.
- `pending_count`, `dropped_count`, `is_closed`, `is_running`, `has_failed`, and `last_error` are mutable runtime refs that power the higher-level lifecycle and diagnostics helpers.
- The sink type parameter is preserved across async composition, which is why helpers such as `with_target(...)`, `with_context_fields(...)`, `with_filter(...)`, and `with_patch(...)` keep returning `AsyncLogger[S]`.
- `async_logger(...)` constructs this type as the main asynchronous entry point.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Root Async Logger Value

When queue-backed logging should begin from a concrete sink-preserving root object:
```moonbit
let logger : AsyncLogger[ConsoleSink] = async_logger(console_sink(), target="app.async")
```

In this example, the root async logger keeps the concrete sink type visible for later typed composition.

#### When Need Worker Control Plus Runtime State

When code should both enqueue logs and inspect async runtime behavior:
```moonbit
let logger = async_logger(console_sink(), config=AsyncLoggerConfig::new(max_pending=32))
ignore(logger.pending_count())
ignore(logger.state())
```

In this example, the root type combines queue-backed logging with explicit runtime observability.

### Error Case

e.g.:
- `AsyncLogger[S]` itself does not have a runtime failure mode.

- Actual enqueue, worker, and flush behavior still depends on the wrapped sink `S`, async runtime support, and the configured queue policy.

- Post-close logging behavior is not a property of the struct shape alone; it also depends on the active runtime implementation.

### Notes

1. Use `async_logger(...)`, `build_async_logger(...)`, or `build_async_text_logger(...)` when you need a value of this type.

2. Use `ApplicationAsyncLogger` or `LibraryAsyncLogger[S]` when a more intention-specific async wrapper or alias fits the calling boundary better.

3. Prefer the method helpers such as `state()`, `has_failed()`, `last_error()`, `is_running()`, and `shutdown()` instead of reading these public fields conceptually as if they were a stable manual mutation surface.
