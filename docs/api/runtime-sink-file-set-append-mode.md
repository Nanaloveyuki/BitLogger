---
name: runtime-sink-file-set-append-mode
group: api
category: runtime
update-time: 20260613
description: Update the append-mode policy used by a file-backed RuntimeSink for later reopen behavior.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-set-append-mode

Update the append-mode policy used by a file-backed `RuntimeSink`. This helper changes future reopen behavior without forcing an immediate reopen on the runtime sink.

### Interface

```moonbit
pub fn RuntimeSink::file_set_append_mode(self : RuntimeSink, append : Bool) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose append-mode policy should change.
- `append : Bool` - New append-mode policy.

#### output

- `Bool` - Whether the policy update was applied.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants update their stored append policy and return `true`.
- `QueuedFile` runtime variants forward the policy update to the wrapped inner `FileSink` and return `true`.
- This helper updates policy only; it does not force immediate reopen.
- Non-file runtime variants return `false`.

### How to Use

Here are some specific examples provided.

#### When Need To Change Future Reopen Behavior On A Runtime Sink

When runtime recovery should later prefer append mode explicitly:
```moonbit
ignore(sink.file_set_append_mode(true))
```

In this example, later reopen operations will use the updated append policy.

#### When Want To Separate Policy Mutation From Reopen Timing

When code should update policy now and reopen later:
```moonbit
ignore(sink.file_set_append_mode(false))
ignore(sink.file_reopen_with_current_policy())
```

In this example, policy mutation and reopen timing remain separate decisions on the runtime sink.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need an immediate reopen as part of the same operation, one of the reopen helpers should be used afterward.

### Notes

1. This helper changes stored policy, not live file-handle state by itself.

2. It is useful when recovery logic wants to stage reopen behavior in advance.
