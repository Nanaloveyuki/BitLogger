---
name: configured-logger-file-reopen
group: api
category: runtime
update-time: 20260512
description: Reopen the file sink behind a configured runtime logger with an optional append-mode override.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-reopen

Reopen the file sink behind a `ConfiguredLogger`. This helper is useful for recovery flows after file unavailability or policy changes.

### Interface

```moonbit
pub fn ConfiguredLogger::file_reopen(self : ConfiguredLogger, append~ : Bool? = None) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose file sink should be reopened.
- `append : Bool?` - Optional append-mode override used for reopen behavior.

#### output

- `Bool` - Whether reopen succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain file sinks reopen directly through the wrapped `RuntimeSink`.
- Queued file sinks forward reopen behavior to the wrapped inner file sink.
- `append=None` preserves current reopen policy, while `Some(true/false)` overrides append mode.
- Non-file sinks return `false`.

### How to Use

Here are some specific examples provided.

#### When Need Recovery After File Failure

When application code should attempt to restore file logging:
```moonbit
ignore(logger.file_reopen())
```

In this example, the configured logger tries to reopen its runtime file sink using current policy.

#### When Need Explicit Append-mode Reopen

When recovery should choose append or truncate behavior explicitly:
```moonbit
let ok = logger.file_reopen(append=Some(true))
```

In this example, reopen behavior is directed by the call site.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers only need the current configured policy, `file_reopen_with_current_policy()` may be the clearer API.

### Notes

1. Use this helper for explicit recovery flows.

2. Pair it with `file_available()` and failure counters when diagnosing reopen behavior.
