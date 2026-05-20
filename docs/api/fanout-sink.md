---
name: fanout-sink
group: api
category: sink
update-time: 20260520
description: Create a sink that writes each record to two sinks.
key-word:
    - sink
    - fanout
    - routing
    - public
---

## Fanout-sink

Create a sink that writes every record to two underlying sinks. This helper is useful when the same log stream should be duplicated across multiple destinations.

### Interface

```moonbit
pub fn[A, B] fanout_sink(left : A, right : B) -> FanoutSink[A, B] {
```

#### input

- `left : A` - First sink destination.
- `right : B` - Second sink destination.

#### output

- `FanoutSink[A, B]` - Sink that duplicates records to both destinations.

### Explanation

Detailed rules explaining key parameters and behaviors

- Each record is written to both sinks.
- The right side receives a copied record so the two writes remain independent at the record value level.
- This helper is useful for combinations such as console plus JSON, or console plus callback capture.

### How to Use

Here are some specific examples provided.

#### When Need Dual Output Paths

When the same records should go to both human and machine-oriented outputs:
```moonbit
let logger = Logger::new(
  fanout_sink(console_sink(), json_console_sink()),
  target="dual",
)
```

In this example, each record is written to both console sinks.

### Error Case

e.g.:
- If only one path should receive a record conditionally, use `split_sink(...)` instead.

- Sink-specific failures still follow the behavior of the wrapped sinks.

### Notes

1. This helper is a duplication primitive, not a conditional router.

2. It is often useful in examples and test capture setups.
