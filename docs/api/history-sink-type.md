---
name: history-sink-type
group: api
category: sink
update-time: 20260811
description: Public bounded in-memory record sink used for diagnostic history.
key-word:
    - sink
    - history
    - type
---

## History-sink-type

`HistorySink` is the concrete synchronous sink returned by `history_sink(...)`.
It retains copied `Record` values in memory and implements `Sink`.

### Interface

```moonbit
pub struct HistorySink {
  records : Ref[Array[Record]]
  capacity : Int
  dropped_count : Ref[Int]
}
```

### Notes

Use `snapshot()` for retained records and the count helpers for bounded-history
observability. The type does not perform persistence or background work.
