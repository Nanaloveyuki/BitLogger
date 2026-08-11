---
name: history-sink-clear
group: api
category: sink
update-time: 20260811
description: Clear a HistorySink and reset its eviction counter.
key-word:
    - sink
    - history
    - clear
---

## History-sink-clear

```moonbit
pub fn HistorySink::clear(self : HistorySink) -> Unit
```

Clears all retained records and resets `dropped_count()` to zero. It does not
close the sink; subsequent records begin a new history session.
