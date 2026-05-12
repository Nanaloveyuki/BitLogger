---
name: level-priority
group: api
category: level
update-time: 20260512
description: Convert a level into its numeric severity priority.
key-word:
    - level
    - priority
    - helper
    - public
---

## Level-priority

Convert a `Level` into its numeric severity priority. This helper provides the ordering used by threshold checks and level comparisons.

### Interface

```moonbit
pub fn Level::priority(self : Level) -> Int {}
```

#### input

- `self : Level` - Level value whose numeric severity should be read.

#### output

- `Int` - Numeric severity where larger numbers represent more severe levels.

### Explanation

Detailed rules explaining key parameters and behaviors

- The built-in priorities are `Trace=10`, `Debug=20`, `Info=30`, `Warn=40`, and `Error=50`.
- These values define the severity ordering used by `Level::enabled(...)` and helpers such as `level_at_least(...)`.
- Callers should treat the mapping as a stable ordering mechanism rather than as user-facing display text.
- Higher priority means higher severity.

### How to Use

Here are some specific examples provided.

#### When Compare Levels Explicitly

When code should compare severities numerically:
```moonbit
if Level::Warn.priority() > Level::Info.priority() {
  logger.info("warn is more severe than info")
}
```

In this example, the numeric mapping drives direct comparison logic.

#### When Build Custom Threshold Logic

When a helper wants to reproduce built-in gating:
```moonbit
fn keep(level : Level, min_level : Level) -> Bool {
  level.priority() >= min_level.priority()
}
```

In this example, the same ordering contract used by the logger API is applied directly.

### Error Case

e.g.:
- There is no failure path for valid `Level` values.

- If code depends on the exact numbers instead of the ordering, future refactoring would be more brittle than necessary.

### Notes

1. Prefer `Level::enabled(...)` when you need threshold semantics rather than raw numeric comparison.

2. `priority()` is primarily an ordering helper, not a display helper.

