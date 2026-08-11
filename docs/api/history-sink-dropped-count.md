---
name: history-sink-dropped-count
group: api
category: sink
update-time: 20260811
description: Read the number of oldest records evicted from a HistorySink.
key-word:
    - sink
    - history
    - dropped
---

## History-sink-dropped-count

```moonbit
pub fn HistorySink::dropped_count(self : HistorySink) -> Int
```

Returns the cumulative number of records evicted because the bounded history was
full. `clear()` resets this count for the new history session.
