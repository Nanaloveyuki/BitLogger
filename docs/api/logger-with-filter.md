---
name: logger-with-filter
group: api
category: logging
update-time: 20260512
description: Wrap a logger with predicate-based filtering so only matching records reach the sink.
key-word:
    - logger
    - filter
    - predicate
    - public
---

## Logger-with-filter

Attach a `RecordPredicate` to a logger so only matching records are forwarded to the wrapped sink. This is the main API for routing-by-predicate at the logger layer without rewriting sink implementations.

### Interface

```moonbit
pub fn[S] Logger::with_filter(self : Logger[S], predicate : (Record) -> Bool) -> Logger[FilterSink[S]] {}
```

#### input

- `self : Logger[S]` - Base logger to wrap.
- `predicate : (Record) -> Bool` - Record predicate that decides whether a record should pass.

#### output

- `Logger[FilterSink[S]]` - A new logger that only forwards matching records.

### Explanation

Detailed rules explaining key parameters and behaviors

- Filtering happens after the record is constructed, so predicates can inspect target, message, level, timestamp, and fields.
- The original logger is not mutated; a wrapped logger is returned.
- Filter logic composes naturally with helper predicates such as `target_has_prefix(...)`, `message_contains(...)`, and `all_of(...)`.
- Filtering is a drop/no-drop decision and does not transform the record itself.

### How to Use

Here are some specific examples provided.

#### When Keep Only One Target Namespace

When a logger should only emit records from a specific subsystem:
```moonbit
let logger = Logger::new(console_sink(), target="service")
  .with_filter(target_has_prefix("service"))
```

In this example, records outside the `service` target prefix are filtered out.

And target-based rules stay reusable across different loggers.

#### When Combine Several Filter Rules

When filtering depends on multiple conditions:
```moonbit
let logger = Logger::new(console_sink(), target="api")
  .with_filter(all_of([
    level_at_least(Level::Warn),
    message_contains("timeout"),
  ]))
```

In this example, only warning-or-higher timeout records are forwarded.

### Error Case

e.g.:
- If the predicate always returns `false`, the logger silently drops every record.

- If the predicate always returns `true`, the wrapper behaves like a pass-through filter.

### Notes

Notes are here.

1. Use this API for selection logic, not record mutation.

2. Prefer helper predicates for readability and reuse.

3. Filtering occurs before sink write, so it is cheaper than post-processing output.

4. If you need record modification too, combine this API with `with_patch(...)`.
