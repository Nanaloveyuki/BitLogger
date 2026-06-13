---
name: file-sink-set-append-mode
group: api
category: sink
update-time: 20260613
description: Update the append-mode policy used by a FileSink for later reopen behavior.
key-word:
    - file
    - sink
    - append
    - public
---

## File-sink-set-append-mode

Update the append-mode policy used by a `FileSink`. This helper changes future reopen behavior on the concrete sink without forcing an immediate reopen.

### Interface

```moonbit
pub fn FileSink::set_append_mode(self : FileSink, append : Bool) -> Unit {
```

#### input

- `self : FileSink` - File sink whose append-mode policy should change.
- `append : Bool` - New append-mode policy.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method updates stored policy only.
- It does not force an immediate reopen.
- The new value affects later reopen behavior.
- The sink path and current rotation policy are left unchanged.

### How to Use

Here are some specific examples provided.

#### When Need To Change Future Reopen Behavior

When direct recovery code should later prefer append mode explicitly:
```moonbit
sink.set_append_mode(true)
```

In this example, later reopen operations use the updated append policy.

#### When Want To Separate Policy Mutation From Reopen Timing

When code should update policy now and reopen later:
```moonbit
sink.set_append_mode(false)
ignore(sink.reopen_with_current_policy())
```

In this example, policy mutation and reopen timing remain separate decisions.

### Error Case

e.g.:
- If callers need an immediate reopen as part of the same operation, one of the reopen helpers should be used afterward.

- This method does not itself prove that the sink is currently available or writable.

### Notes

1. This helper changes stored policy, not live file-handle state by itself.

2. It is useful when direct file-sink recovery logic wants to stage reopen behavior in advance.
