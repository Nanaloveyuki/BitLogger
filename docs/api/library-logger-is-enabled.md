---
name: library-logger-is-enabled
group: api
category: facade
update-time: 20260613
description: Check whether a LibraryLogger facade passes the wrapped logger's min-level gate for a given severity.
key-word:
    - library
    - facade
    - enabled
    - public
---

## Library-logger-is-enabled

Check whether a `LibraryLogger[S]` would accept a record at the given level based on its current `min_level`. This is the library-facing counterpart to `Logger::is_enabled(...)` and is useful for gating expensive message preparation.

### Interface

```moonbit
pub fn[S] LibraryLogger::is_enabled(self : LibraryLogger[S], level : Level) -> Bool {
```

#### input

- `self : LibraryLogger[S]` - Library-facing logger whose current minimum level should be checked.
- `level : Level` - Candidate severity to test.

#### output

- `Bool` - `true` when the level is enabled by the facade's current threshold.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates directly to the wrapped logger's `is_enabled(...)` behavior.
- It only checks logger-level severity gating through `min_level`; it does not evaluate later sink filters, patch logic, or any sink-side buffering/wrapping behavior.
- The result reflects the current wrapped logger state, so derived facades with different thresholds can return different answers.
- This check does not require unwrapping because it is part of the narrower library-facing surface.
- Use it when message construction or field gathering is expensive enough to justify a pre-check.

### How to Use

Here are some specific examples provided.

#### When Avoid Expensive Library Debug Preparation

When debug data should only be built if needed:
```moonbit
if logger.is_enabled(Level::Debug) {
  logger.info(build_summary())
}
```

In this example, expensive preparation is skipped unless the current threshold allows that severity.

#### When Inspect Effective Facade Threshold

When package code should branch based on current logger behavior:
```moonbit
if logger.is_enabled(Level::Info) {
  logger.info("library path active")
}
```

In this example, the check mirrors the same severity gate used by later write calls.

And a `true` result still means only that the level gate passed, not that the record is guaranteed to survive later sink-side filtering or routing.

### Error Case

e.g.:
- If `level` is below the current minimum threshold, the method returns `false`.

- A `true` result does not guarantee final sink output if later filter logic rejects the record.

- If callers need broader composition helpers rather than just the level gate, they must unwrap first with `to_logger()`.

### Notes

1. This is a cheap severity check, not a full end-to-end delivery guarantee.

2. Prefer using it only when precomputing the log payload is meaningfully expensive.

3. Use `log(...)` or the severity shortcuts directly when no expensive precomputation needs to be avoided.
