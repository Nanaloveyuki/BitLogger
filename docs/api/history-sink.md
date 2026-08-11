---
name: history-sink
group: api
category: sink
update-time: 20260811
description: Create a bounded in-memory sink that retains the latest structured records.
key-word:
    - sink
    - history
    - memory
    - diagnostics
---

## History-sink

Create a synchronous in-memory sink for bounded diagnostic history. It retains
the newest records and does not write to a file, console, or network endpoint.

### Interface

```moonbit
pub fn history_sink(capacity? : Int = 128) -> HistorySink
```

### Explanation

- `capacity` is normalized to at least `1`; the default keeps the latest `128`
  records.
- When full, the oldest record is evicted and `dropped_count()` increases.
- `snapshot()` returns records ordered from oldest to newest. `clear()` starts a
  new in-memory history session.

### How to Use

```moonbit
let history = history_sink(capacity=64)
let logger = Logger::new(history, target="desktop")
logger.info("runtime ready")
let records = history.snapshot()
```

### Notes

`HistorySink` is synchronous and application-owned. Serialize or persist a
snapshot explicitly when needed.
