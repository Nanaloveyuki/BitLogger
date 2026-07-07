---
name: configured-logger-file-default-policy
group: api
category: runtime
update-time: 20260707
description: Read the initial default file policy associated with a configured logger, with a compatibility fallback for non-file sinks.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-default-policy

Read the initial default file policy associated with a `ConfiguredLogger`. This helper exposes the baseline file policy captured when the runtime sink was created.

The returned `FileSinkPolicy` value is owned by `src/file_model`; this configured-logger surface is a facade over `Logger[@runtime.RuntimeSink]` and delegates default-policy reads to the wrapped `RuntimeSink`.

`file_default_policy()` is the compatibility form. For truthful file-semantics detection, prefer `file_default_policy_or_none()`.

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

- File-backed sinks return the default policy captured at creation time through the wrapped `RuntimeSink`.
- Queued file sinks forward the default policy from the wrapped inner file sink.
- The returned policy object itself is the shared `@file_model.FileSinkPolicy` model, not a configured-logger-owned concrete type.
- Non-file sinks return the same neutral fallback policy value produced by `RuntimeSink::file_default_policy()`.
- This fallback keeps older callers source-compatible, but it is not a real file default policy.
- New diagnostic or recovery code should prefer `file_default_policy_or_none()`.
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

- If callers need a truthful file-semantics check, use `file_default_policy_or_none()`.

- If callers only need to know whether runtime drift exists, `file_policy_matches_default()` is the simpler API.

### Notes

1. Use this helper when the original file policy matters operationally.

2. It complements `file_policy()` and `file_reset_policy()`, while `file_default_policy_or_none()` is the truthful diagnostic form.
