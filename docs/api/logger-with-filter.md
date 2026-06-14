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

- `Logger[FilterSink[S]]` - A new logger value whose visible sink type becomes `FilterSink[S]` and only forwards matching records.

### Explanation

Detailed rules explaining key parameters and behaviors

- Filtering happens after the record is constructed, so predicates can inspect target, message, level, timestamp, and fields.
- The original logger is not mutated; a derived wrapped logger is returned.
- The returned logger changes visible type from `Logger[S]` to `Logger[FilterSink[S]]` because the sink pipeline is extended with predicate filtering.
- Stored target, minimum level, and timestamp behavior are preserved while the sink pipeline changes.
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

The returned logger still uses the same ordinary synchronous logging calls; only the sink path now includes filtering.

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

1. Use this API for selection logic, not record mutation.

2. Prefer helper predicates for readability and reuse.

3. Use a derived logger value when one path should enforce extra predicate rules and another should keep writing through the original sink unchanged.

