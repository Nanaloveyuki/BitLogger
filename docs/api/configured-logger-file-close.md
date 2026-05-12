---
name: configured-logger-file-close
group: api
category: runtime
update-time: 20260512
description: Close the file sink behind a configured runtime logger when one is present.
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

- `Bool` - Whether the underlying file close succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain file sinks forward directly to file close behavior.
- Queued file sinks flush queue work before closing the wrapped file sink.
- Non-file sinks return `false`.
- This helper is narrower than generic `close()` because it specifically targets file sink shutdown.

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

In this example, the result describes file close behavior rather than generic sink close behavior.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers only need generic sink teardown, `close()` is the broader API.

### Notes

1. Prefer this helper when file-backed runtime behavior matters specifically.

2. Queued file sinks may flush pending records before closing the file.
