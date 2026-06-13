---
name: level
group: api
category: level
update-time: 20260613
description: Public level enum alias shared by records, filters, and logger thresholds.
key-word:
    - level
    - alias
    - severity
    - public
---

## Level

`Level` is the public severity enum used across records, filters, and logger threshold checks. It is a direct alias to the core level type, so the same five built-in variants are shared everywhere the public API accepts or returns a level.

### Interface

```moonbit
pub type Level = @core.Level
```

#### output

- `Level` - Public severity enum with the variants `Trace`, `Debug`, `Info`, `Warn`, and `Error`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a wrapper or a separate enum.
- The built-in variants are `Level::Trace`, `Level::Debug`, `Level::Info`, `Level::Warn`, and `Level::Error`.
- `Level` is used by `Record::new(...)`, logger threshold APIs, predicate helpers, and config-driven builders.
- Ordering and display behavior come from the same underlying type, so helpers such as `priority()`, `label()`, and `enabled(...)` work on this alias unchanged.

### How to Use

Here are some specific examples provided.

#### When Need A Severity For New Records

When a record should be created with a concrete severity:
```moonbit
let rec = Record::new(Level::Warn, "disk almost full")
```

In this example, the record uses the public `Level` alias directly.

#### When Need A Threshold For Logger Filtering

When a logger should only accept records at or above one severity:
```moonbit
let logger = Logger::new(console_sink()).with_min_level(Level::Info)
```

In this example, the same public level enum is reused as the threshold value.

### Error Case

e.g.:
- `Level` itself does not have a runtime failure mode.

- If external config text names an unsupported level string, parsing fails through `ConfigError` instead of producing a fallback level.

### Notes

1. Use `label()` for display text and `priority()` or `enabled(...)` for threshold logic.

2. This alias keeps sync APIs, async APIs, and config builders on the same severity vocabulary.
