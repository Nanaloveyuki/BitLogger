---
name: configured-logger-file-set-append-mode
group: api
category: runtime
update-time: 20260512
description: Update the append-mode policy used by the configured runtime file sink for later reopen behavior.
key-word:
    - logger
    - runtime
    - file
    - public
---

## Configured-logger-file-set-append-mode

Update the append-mode policy used by a `ConfiguredLogger` file sink. This helper changes future reopen behavior without forcing an immediate reopen.

### Interface

```moonbit
pub fn ConfiguredLogger::file_set_append_mode(self : ConfiguredLogger, append : Bool) -> Bool {}
```

#### input

- `self : ConfiguredLogger` - Config-driven runtime logger whose append-mode policy should change.
- `append : Bool` - New append-mode policy.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- File-backed sinks update their stored append policy through the wrapped `RuntimeSink`.
- Queued file sinks forward the policy update to the wrapped inner file sink.
- This helper updates policy only; it does not force immediate reopen.
- Non-file sinks return `false`.

### How to Use

Here are some specific examples provided.

#### When Need To Change Future Reopen Behavior

When runtime recovery should later prefer append mode explicitly:
```moonbit
ignore(logger.file_set_append_mode(true))
```

In this example, later reopen operations will use the updated append policy.

#### When Want To Separate Policy Mutation From Reopen Timing

When code should update policy now and reopen later:
```moonbit
ignore(logger.file_set_append_mode(false))
ignore(logger.file_reopen_with_current_policy())
```

In this example, policy mutation and reopen timing remain separate decisions.

### Error Case

e.g.:
- If the configured sink is not file-backed, the method returns `false`.

- If callers need an immediate reopen as part of the same operation, one of the reopen helpers should be used afterward.

### Notes

1. This helper changes stored policy, not live file-handle state by itself.

2. It is useful when recovery logic wants to stage reopen behavior in advance.
