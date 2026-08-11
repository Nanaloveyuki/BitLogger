---
name: history-sink-snapshot
group: api
category: sink
update-time: 20260811
description: Copy the retained records from a HistorySink in chronological order.
key-word:
    - sink
    - history
    - snapshot
---

## History-sink-snapshot

```moonbit
pub fn HistorySink::snapshot(self : HistorySink) -> Array[Record]
```

Returns copied records ordered from oldest to newest. Later writes and mutation
of the returned array do not change the retained history.
