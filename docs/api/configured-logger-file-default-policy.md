---
name: configured-logger-file-default-policy
group: api
category: runtime
update-time: 20260512
description: Read the initial default file policy associated with a configured file-backed logger.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-default-policy

Read the initial default file policy associated with a `ConfiguredLogger`. This helper exposes the baseline file policy captured when the runtime sink was created.

### Interface

```moonbit
pub fn ConfiguredLogger::file_default_policy(self : ConfiguredLogger) -> FileSinkPolicy {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose default file policy should be inspected.

#### output

- `FileSinkPolicy` - Initial default file policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks return the default policy captured at creation time.
- Queued file sinks forward the default policy from the wrapped file sink.
- Non-file sinks return a neutral fallback policy value.
- This helper is useful when callers need to compare runtime drift or restore defaults later.

### How to Use

Here are some specific examples provided.

#### When Need Baseline Policy Visibility

When diagnostics should show the original file policy separately from the live one:
```moonbit
let defaults = logger.file_default_policy()
```

In this example, the configured logger exposes its original file policy snapshot.

#### When Prepare For Policy Reset Logic

When tooling should capture or compare default settings explicitly:
```moonbit
let original = logger.file_default_policy()
```

In this example, callers can reason about “factory” file policy separately from runtime changes.

### Error Case

e.g.:
- If the configured sink is not file-backed, the return value is a neutral fallback policy.

- If callers only need to know whether runtime drift exists, `file_policy_matches_default()` is the simpler API.

### Notes

1. Use this helper when the original file policy matters operationally.

2. It complements `file_policy()` and `file_reset_policy()`.
