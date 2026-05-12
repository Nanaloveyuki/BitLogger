---
name: level-enabled
group: api
category: level
update-time: 20260512
description: Check whether a level passes a minimum threshold.
key-word:
    - level
    - enabled
    - threshold
    - public
---

## Level-enabled

Check whether a `Level` passes a given minimum threshold. This is the core severity-gating helper used by synchronous and async logger `is_enabled(...)` checks.

### Interface

```moonbit
pub fn Level::enabled(self : Level, min_level : Level) -> Bool {}
```

#### input

- `self : Level` - Candidate level being tested.
- `min_level : Level` - Minimum threshold the candidate must meet or exceed.

#### output

- `Bool` - `true` when `self.priority() >= min_level.priority()`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The method compares levels by their numeric priority ordering.
- Matching the threshold exactly still counts as enabled.
- This helper is the level-level primitive behind logger threshold checks.
- It is useful when threshold logic should be expressed without requiring a logger instance.

### How to Use

Here are some specific examples provided.

#### When Test A Level Against A Threshold

When code wants direct threshold logic:
```moonbit
let enabled = Level::Warn.enabled(Level::Info)
```

In this example, `enabled` is `true` because `Warn` is above `Info`.

#### When Reuse Logger-style Gating In Helpers

When a utility should mirror logger severity checks:
```moonbit
if level.enabled(Level::Debug) {
  logger.info("level is active")
}
```

In this example, the same ordering rule used by logger APIs is applied directly.

### Error Case

e.g.:
- There is no failure path for valid level values.

- If callers need to know whether a record survives filters or sinks, `enabled()` alone is not sufficient because it only covers severity gating.

### Notes

1. Use this helper when threshold logic should stay independent of any logger instance.

2. Prefer `Logger::is_enabled(...)` when you already have a logger and want to respect its configured minimum level directly.

