---
name: history-sink-capacity
group: api
category: sink
update-time: 20260811
description: Read the normalized retention capacity of a HistorySink.
key-word:
    - sink
    - history
    - capacity
---

## History-sink-capacity

```moonbit
pub fn HistorySink::capacity(self : HistorySink) -> Int
```

Returns the positive retention limit selected when the sink was constructed.
