---
name: configured-logger-file-append-mode
group: api
category: runtime
update-time: 20260512
description: Read the current append-mode policy used by the configured runtime file sink.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-append-mode

Read the current append-mode policy used by a `ConfiguredLogger` file sink. This helper exposes whether future reopen behavior is currently append-oriented.

### Interface

```moonbit
pub fn ConfiguredLogger::file_append_mode(self : ConfiguredLogger) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose append-mode policy should be inspected.

#### output

- `Bool` - Current append-mode policy for the file sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks report their current append policy.
- Queued file sinks forward the policy from the wrapped file sink.
- Non-file sinks return `false`.
- This helper reports runtime file policy, not whether a file is currently writable.

### How to Use

Here are some specific examples provided.

#### When Need Runtime Append-policy Visibility

When diagnostics should show how future reopen behavior is configured:
```moonbit
let append = logger.file_append_mode()
```

In this example, the configured logger exposes current reopen policy directly.

#### When Validate Runtime Policy Changes

When policy mutation should be observable after a setter call:
```moonbit
ignore(logger.file_set_append_mode(true))
ignore(logger.file_append_mode())
```

In this example, callers verify the updated append-mode policy.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need the full current file policy rather than just append mode, `file_policy()` is the better API.

### Notes

1. Use this helper when append policy is the only file setting you need to inspect.

2. Pair it with reopen helpers when debugging runtime file behavior.
