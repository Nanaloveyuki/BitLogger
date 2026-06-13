---
name: async-runtime-state-new
group: api
category: async
update-time: 20260614
description: Construct an AsyncRuntimeState snapshot from explicit runtime mode and worker-support values without probing or validating the live backend.
key-word:
    - async
    - runtime
    - state
    - public
---

## Async-runtime-state-new

Construct an `AsyncRuntimeState` snapshot from explicit runtime mode and worker-support values. This is the low-level constructor behind the public async runtime state shape used in diagnostics.

### Interface

```moonbit
pub fn AsyncRuntimeState::new(
  mode : AsyncRuntimeMode,
  background_worker : Bool,
) -> AsyncRuntimeState {
```

#### input

- `mode : AsyncRuntimeMode` - Backend-specific async runtime mode such as `NativeWorker` or `Compatibility`.
- `background_worker : Bool` - Whether native-style background-worker support is available.

#### output

- `AsyncRuntimeState` - Runtime state snapshot containing the supplied mode and worker-support flag.

### Explanation

Detailed rules explaining key parameters and behaviors

- This constructor simply packages `mode` and `background_worker` into one public snapshot value.
- It does not query the current backend automatically.
- `async_runtime_state()` is the higher-level API that reads these values from the live runtime environment.
- It also does not validate whether the supplied pair matches the current backend contract.
- The constructed value matches the same public shape used by async runtime serializers.

### How to Use

Here are some specific examples provided.

#### When Need A Hand-built Runtime Snapshot

When tests or adapters should construct a runtime state explicitly:
```moonbit
let runtime = AsyncRuntimeState::new(
  AsyncRuntimeMode::Compatibility,
  false,
)
```

In this example, the runtime snapshot is built directly without probing the active backend.

#### When Need Structured Runtime Diagnostics Input

When code should prepare a runtime state value before serialization:
```moonbit
let runtime = AsyncRuntimeState::new(async_runtime_mode(), async_runtime_supports_background_worker())
```
In this example, callers still use the direct constructor while keeping the data source explicit.

### Error Case

e.g.:
- This constructor itself does not have a normal failure mode; it only packages the provided values.

- If callers want the current backend snapshot directly, `async_runtime_state()` is the simpler API.

- If callers manually pair `NativeWorker` with `false` or `Compatibility` with `true`, the constructor still accepts that snapshot because it does not enforce backend consistency.

### Notes

1. Use this helper when code should construct an `AsyncRuntimeState` value explicitly.

2. Pair it with `AsyncLoggerState::new(...)` when assembling a full async logger snapshot by hand.

3. Prefer `async_runtime_state()` when the goal is to report the actual current backend pair rather than an arbitrary constructed snapshot.
