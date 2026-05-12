---
name: async-runtime-mode
group: api
category: async
update-time: 20260512
description: Read the current async runtime mode and distinguish native worker behavior from compatibility behavior.
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
- `async_runtime_mode_label(...)` converts the enum into a stable string value.
- `async_runtime_supports_background_worker()` is a narrower boolean probe built on the same idea.
- This API is intentionally small and useful for lightweight branching.

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

