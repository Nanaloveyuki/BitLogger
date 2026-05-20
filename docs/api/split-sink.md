---
name: split-sink
group: api
category: sink
update-time: 20260520
description: Create a sink that routes records to one of two sinks using a predicate.
key-word:
    - sink
    - split
    - routing
    - public
---

## Split-sink

Create a sink that routes each record to one of two sinks based on a predicate. This helper is useful for target-based or policy-based sink routing.

### Interface

```moonbit
pub fn[A, B] split_sink(left : A, right : B, predicate : (Record) -> Bool) -> SplitSink[A, B] {
```

#### input

- `left : A` - Sink receiving records when the predicate returns `true`.
- `right : B` - Sink receiving records when the predicate returns `false`.
- `predicate : (Record) -> Bool` - Routing function evaluated for each record.

#### output

- `SplitSink[A, B]` - Conditional routing sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- The predicate decides which side receives each record.
- Unlike `fanout_sink(...)`, a record is routed to one side only.
- This helper is useful for target-aware and content-aware routing policies.

### How to Use

Here are some specific examples provided.

#### When Need Predicate-based Routing

When audit records should go to a different destination:
```moonbit
let sink = split_sink(console_sink(), json_console_sink(), fn(rec) {
  rec.target == "audit"
})
```

In this example, only records matching the predicate go to the left sink.

### Error Case

e.g.:
- If both destinations should always receive the same record, use `fanout_sink(...)` instead.

- Predicate logic is caller-defined, so misrouting comes from predicate choice rather than sink mechanics.

### Notes

1. This helper is a routing primitive for synchronous sink composition.

2. `split_by_level(...)` is a convenience wrapper for level-based routing.
