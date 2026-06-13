---
name: async-runtime-mode
group: api
category: async
update-time: 20260614
description: Read the current async runtime mode and distinguish native-worker behavior from compatibility behavior using the same mode contract exposed through async runtime snapshots.
key-word:
    - async
    - runtime
    - mode
    - public
---

## Async-runtime-mode

Read the current backend-specific async runtime mode. This API is the narrowest capability probe when you only care whether the current build is running native worker semantics or compatibility behavior.

### Interface

```moonbit
pub fn async_runtime_mode() -> AsyncRuntimeMode {}
```

#### input

- `none` - No arguments are required.

#### output

- `AsyncRuntimeMode` - Either `NativeWorker` or `Compatibility`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The return value is determined by the active backend implementation.
- `NativeWorker` is the expected mode on native-style backends, while `Compatibility` is the expected mode on targets without native background-worker semantics.
- `async_runtime_mode_label(...)` converts the enum into a stable string value.
- `async_runtime_supports_background_worker()` is a narrower boolean probe built on the same idea.
- `async_runtime_state()` packages this mode together with the current background-worker capability into one `AsyncRuntimeState` snapshot.
- In the current backend implementations, `NativeWorker` pairs with `background_worker=true` and `Compatibility` pairs with `background_worker=false`.
- Concretely, the native runtime entrypoint returns `native_worker_async_runtime_mode()`, while the compatibility stub returns `compatibility_async_runtime_mode()`.
- This API is intentionally small and useful for lightweight branching.
- The mode result describes runtime behavior only; it should not be read as proof that every backend has been equally re-verified in the current release cycle.

### How to Use

Here are some specific examples provided.

#### When Need A Small Capability Branch

When behavior should differ between native worker mode and compatibility mode:
```moonbit
match async_runtime_mode() {
  AsyncRuntimeMode::NativeWorker => println("native worker")
  AsyncRuntimeMode::Compatibility => println("compat")
}
```

In this example, the branch is explicit and readable.

#### When Need Stable String Output

When the mode should be included in logs or telemetry labels:
```moonbit
println(async_runtime_mode_label(async_runtime_mode()))
```

In this example, the output becomes a stable string instead of an enum pattern-match requirement.

### Error Case

e.g.:
- This API does not have a normal runtime failure mode; it reflects the compiled backend behavior.

- If you need worker support as a direct boolean, use `async_runtime_supports_background_worker()` instead.

### Notes

1. Use this API for minimal mode branching.

2. Use `async_runtime_state()` when you also want worker support packaged into one object.

3. Use `async_runtime_mode_label(...)` when the result should leave enum space and become stable text such as `native_worker` or `compatibility`.

4. This mode distinction is about runtime behavior, not whether `src-async` itself is expected to compile for the target.

5. See [target-verification.md](./target-verification.md) for the current verification status of individual targets.
