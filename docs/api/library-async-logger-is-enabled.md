---
name: library-async-logger-is-enabled
group: api
category: facade
update-time: 20260614
description: Check whether a LibraryAsyncLogger facade would accept a record at a given level before using the repo's direct async call style.
key-word:
    - async
    - library
    - enabled
    - public
---

## Library-async-logger-is-enabled

Check whether a `LibraryAsyncLogger[S]` would accept a record at the given level based on its current `min_level`. This is the library-facing counterpart to `AsyncLogger::is_enabled(...)` and is useful for gating expensive async message preparation.

### Interface

```moonbit
pub fn[S] LibraryAsyncLogger::is_enabled(
  self : LibraryAsyncLogger[S],
  level : @bitlogger.Level,
) -> Bool {
```

#### input

- `self : LibraryAsyncLogger[S]` - Library-facing async logger whose current minimum level should be checked.
- `level : @bitlogger.Level` - Candidate severity to test.

#### output

- `Bool` - `true` when the level is enabled by the facade's current threshold.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates directly to the wrapped async logger's `is_enabled(...)` behavior.
- It only checks logger-level severity gating; it does not evaluate later filter or overflow behavior.
- The result reflects the current facade value, so derived facades with different thresholds can return different answers.
- Use it when message construction or field gathering is expensive enough to justify a pre-check.

### How to Use

Here are some specific examples provided.

#### When Avoid Expensive Async Debug Preparation

When debug data should only be built if needed:
```moonbit
if logger.is_enabled(@bitlogger.Level::Info) {
  logger.info(build_summary())
}
```

In this example, expensive preparation is skipped unless the current threshold allows that severity.

#### When Inspect Effective Async Facade Threshold

When package code should branch based on current logger behavior:
```moonbit
if logger.is_enabled(@bitlogger.Level::Warn) {
  logger.warn("slow path active")
}
```

In this example, the check mirrors the same severity gate used by later async write calls.

### Error Case

e.g.:
- If `level` is below the current minimum threshold, the method returns `false`.

- A `true` result does not guarantee final delivery if later queue or filter behavior rejects the record.

### Notes

1. This is a cheap severity check, not a full end-to-end delivery guarantee.

2. Prefer using it only when precomputing the async log payload is meaningfully expensive.
