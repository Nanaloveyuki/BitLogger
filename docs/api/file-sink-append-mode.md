---
name: file-sink-append-mode
group: api
category: sink
update-time: 20260613
description: Read the current append-mode policy used by a FileSink.
key-word:
    - file
    - sink
    - append
    - public
---

## File-sink-append-mode

Read the current append-mode policy used by a `FileSink`. This helper exposes whether future reopen behavior is currently append-oriented for the concrete sink value.

### Interface

```moonbit
pub fn FileSink::append_mode(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink whose current append-mode policy should be inspected.

#### output

- `Bool` - Current append-mode policy for the sink.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method reads the sink's current runtime append policy.
- The value affects later `reopen(...)` behavior.
- It does not report whether a file is currently writable or available.
- This helper does not mutate sink state.

### How to Use

Here are some specific examples provided.

#### When Need Direct Append-policy Visibility

When diagnostics should show how future reopen behavior is configured:
```moonbit
let append = sink.append_mode()
```

In this example, the concrete file sink exposes its current append policy directly.

#### When Validate Policy Updates

When a setter call should be observed immediately:
```moonbit
sink.set_append_mode(true)
ignore(sink.append_mode())
```

In this example, callers verify the updated append-mode policy on the sink itself.

### Error Case

e.g.:
- If callers need the full current file policy rather than just append mode, `policy()` is the better API.

- This helper alone does not prove the sink is currently open; use `is_available()` for that.

### Notes

1. Use this helper when append policy is the only file setting you need to inspect.

2. Pair it with reopen helpers when debugging direct file-sink behavior.
