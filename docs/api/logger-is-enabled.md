---
name: logger-is-enabled
group: api
category: logging
update-time: 20260512
description: Check whether a logger would accept a record at a given level.
key-word:
    - logger
    - level
    - enabled
    - public
---

## Logger-is-enabled

Check whether a logger would accept a record at the given level based on its current `min_level`. This API is useful for gating expensive work before building message text or fields.

### Interface

```moonbit
pub fn[S] Logger::is_enabled(self : Logger[S], level : Level) -> Bool {}
```

#### input

- `self : Logger[S]` - Logger whose current minimum level should be checked.
- `level : Level` - Candidate severity to test.

#### output

- `Bool` - `true` when the level is enabled by the logger's current threshold.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method delegates to `level.enabled(self.min_level)`.
- It only checks logger-level severity gating; it does not evaluate sink filters or patch logic.
- The result reflects the current logger value, so derived loggers with different `min_level` settings can return different answers.
- Use it when message construction or field gathering is expensive enough to justify a pre-check.

### How to Use

Here are some specific examples provided.

#### When Avoid Expensive Debug Preparation

When debug data should only be built if needed:
```moonbit
if logger.is_enabled(Level::Debug) {
  logger.debug(build_debug_snapshot())
}
```

In this example, expensive string construction is skipped unless debug logging is enabled.

#### When Inspect Effective Logger Threshold

When code should branch based on current logger behavior:
```moonbit
if logger.is_enabled(Level::Trace) {
  logger.trace("trace path active")
}
```

In this example, the check mirrors the same severity gate used by `log(...)`.

### Error Case

e.g.:
- If `level` is below the current minimum threshold, the method returns `false`.

- A `true` result does not guarantee final sink output if later filter logic rejects the record.

### Notes

1. This is a cheap severity check, not a full end-to-end delivery guarantee.

2. Prefer using it only when precomputing the log payload is meaningfully expensive.

