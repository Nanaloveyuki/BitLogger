---
name: runtime-sink-file-append-mode
group: api
category: runtime
update-time: 20260613
description: Read the current append-mode policy used by a file-backed RuntimeSink.
key-word:
    - runtime
    - sink
    - file
    - public
---

## Runtime-sink-file-append-mode

Read the current append-mode policy used by a file-backed `RuntimeSink`. This helper exposes whether future reopen behavior is currently append-oriented on the runtime sink itself.

### Interface

```moonbit
pub fn RuntimeSink::file_append_mode(self : RuntimeSink) -> Bool {
```

#### input

- `self : RuntimeSink` - Runtime sink whose append-mode policy should be inspected.

#### output

- `Bool` - Current append-mode policy for the file sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- Plain `File` runtime variants report the current append policy from the wrapped `FileSink`.
- `QueuedFile` runtime variants forward the policy from the wrapped inner `FileSink`.
- Non-file runtime variants return `false`.
- This helper reports runtime file policy, not whether a file is currently writable.

### How to Use

Here are some specific examples provided.

#### When Need Direct Runtime Append-policy Visibility

When diagnostics should show how future reopen behavior is configured on a `RuntimeSink`:
```moonbit
let append = sink.file_append_mode()
```

In this example, the runtime sink exposes current reopen policy directly.

#### When Validate Direct Policy Changes

When policy mutation should be observable after a direct setter call:
```moonbit
ignore(sink.file_set_append_mode(true))
ignore(sink.file_append_mode())
```

In this example, callers verify the updated append-mode policy on the runtime sink itself.

### Error Case

e.g.:
- If the runtime sink is not file-backed, the method returns `false`.

- If callers need the full current file policy rather than just append mode, `file_policy()` is the better API.

### Notes

1. Use this helper when append policy is the only file setting you need to inspect.

2. Pair it with reopen helpers when debugging direct runtime file behavior.
