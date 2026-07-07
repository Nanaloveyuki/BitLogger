---
name: configured-logger-file-close
group: api
category: runtime
update-time: 20260707
description: Close the file sink behind a configured runtime logger when one is present, with queued-file success tied to safe drain-flush-close behavior.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-close

Close the file sink behind a `ConfiguredLogger`. This helper is the file-specific runtime close surface for config-built file loggers.

### Interface

```moonbit
pub fn ConfiguredLogger::file_close(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file sink should be closed.

#### output

- `Bool` - Whether the file-specific close path succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain file sinks forward directly to file close behavior through the wrapped `RuntimeSink`.
- Queued file sinks first drain the queue, then flush the wrapped inner file sink, then close it.
- For queued file sinks, the returned `Bool` is `true` only when that whole path succeeds and no new write, flush, or rotation failures are observed during the drain-flush-close step.
- Non-file sinks return `false`.
- This helper is narrower than generic `close()` because it specifically targets file sink shutdown.
- After a file-backed configured logger has already cleared its file handle, later `file_close()` calls return `false`.

### How to Use

Here are some specific examples provided.

#### When Need File-specific Runtime Teardown

When a config-built file logger should close its file handle explicitly:
```moonbit
ignore(logger.file_close())
```

In this example, file teardown happens through the configured logger facade.

#### When Need A File-specific Close Result

When application code wants the file close outcome directly:
```moonbit
let closed = logger.file_close()
```

In this example, the result describes the file-specific close path rather than generic sink close behavior.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If the file handle was already closed earlier through this logger or another facade sharing the same wrapped runtime sink state, the method returns `false`.

- If callers only need generic sink teardown, `close()` is the broader API.

- On queued file sinks, `true` still does not mean a stronger durability contract than the current backend can report; it means the safe drain-flush-close path completed without a newly observed file failure.

### Notes

1. Prefer this helper when file-backed runtime behavior matters specifically.

2. Generic `close()` now uses the same safe queued-file teardown path.

3. Library or application facades derived from the same configured runtime logger still observe the same underlying file-close state.
