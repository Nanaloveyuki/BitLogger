---
name: configured-logger-file-flush
group: api
category: runtime
update-time: 20260614
description: Flush the file sink behind a configured runtime logger when one is present.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-flush

Flush the file sink behind a `ConfiguredLogger`. This helper is the file-specific runtime flush surface for config-built file loggers.

### Interface

```moonbit
pub fn ConfiguredLogger::file_flush(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file sink should be flushed.

#### output

- `Bool` - Whether the underlying file flush succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain file sinks forward directly to file flush behavior through the wrapped `RuntimeSink`.
- Queued file sinks first flush queued records, then flush the wrapped inner file sink.
- For queued file sinks, the returned `Bool` comes from the inner file flush rather than the queue flush step.
- For queued file sinks, this step may also be the point where queued records finally hit the inner file sink, so write-failure counters can change here even if earlier log calls only queued records.
- Non-file sinks return `false`.
- This helper is narrower than generic `flush()` because it targets file sink behavior specifically.
- After a file-backed configured logger has already cleared its file handle, later `file_flush()` calls return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Explicit File Durability Steps

When a config-built file logger should flush to disk explicitly:
```moonbit
ignore(logger.file_flush())
```

In this example, the file-backed runtime sink is flushed directly through the configured logger.

#### When Need A File-specific Success Flag

When code should branch on the outcome of a file flush:
```moonbit
let ok = logger.file_flush()
```

In this example, callers can distinguish file flush success from a non-file sink shape.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If the file handle was already closed earlier through this logger or another facade sharing the same wrapped runtime sink state, the method returns `false`.

- If callers want generic queue or sink advancement instead of file-specific behavior, `flush()` is the broader API.

### Notes

1. Prefer this helper when the configured sink is known to be file-backed.

2. Queued file sinks may perform both queue flush and file flush work here, including surfacing delayed write failures from previously queued records.

3. Library or application facades derived from the same configured runtime logger still observe the same underlying file-flush availability state.
