---
name: native-files-supported
group: api
category: sink
update-time: 20260613
description: Query whether the current backend provides real host file support for file sink operations.
key-word:
    - native
    - file
    - support
    - public
---

## Native-files-supported

Query whether the current backend provides real file support for `file_sink(...)` and related file runtime operations. This helper is the public capability gate for code that needs to decide whether host file logging is actually available on the current target.

### Interface

```moonbit
pub fn native_files_supported() -> Bool {}
```

#### output

- `Bool` - `true` when the active backend provides real file support, otherwise `false`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper is target-sensitive runtime capability detection, not a compile-time type gate.
- The native backend currently returns `true`.
- The stub backend used for non-file-capable targets currently returns `false`.
- File APIs can remain part of the broader portable surface, but callers should use this check before depending on actual file creation, writes, flushes, or reopen behavior.

### How to Use

Here are some specific examples provided.

#### When Need Safe Cross-target File Logging

When code should enable file output only on targets that really support it:
```moonbit
if native_files_supported() {
  let sink = file_sink("app.log")
  Logger::new(sink).info("started")
}
```

In this example, file logging is activated only when the backend can actually provide it.

#### When Need To Match Runtime Availability Checks

When capability detection should align with file sink health state:
```moonbit
let sink = file_sink("app.log")
inspect(sink.is_available() == native_files_supported(), content="true")
```

In this example, the public support flag matches the observable file sink availability contract.

### Error Case

e.g.:
- If this helper returns `false`, callers should not treat file writes, flushes, or reopen operations as available runtime behavior.

- If this helper returns `true`, individual file operations can still fail later because of path, permission, or filesystem state issues.

### Notes

1. Use this helper as the first portability guard around `file_sink(...)`, `file(...)`, and file-runtime control APIs.

2. See [target-verification.md](./target-verification.md) when you need the current local verification boundary for target-sensitive behavior.
