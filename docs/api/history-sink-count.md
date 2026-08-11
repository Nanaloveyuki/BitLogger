---
name: history-sink-count
group: api
category: sink
update-time: 20260811
description: Read the number of records currently retained by a HistorySink.
key-word:
    - sink
    - history
    - count
---

## History-sink-count

```moonbit
pub fn HistorySink::count(self : HistorySink) -> Int
```

Returns the current retained-record count, which never exceeds `capacity()`.
