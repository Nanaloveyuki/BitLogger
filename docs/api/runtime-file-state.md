---
name: runtime-file-state
group: api
category: runtime
update-time: 20260707
description: Public combined file-and-queue runtime state re-exported from file_model for runtime diagnostics.
key-word:
    - runtime
    - file
    - state
    - public
---

## Runtime-file-state

`RuntimeFileState` is the public snapshot object that combines file state with queue runtime context for file-backed runtime diagnostics. On the root `src` facade, it is re-exported from `src/file_model`, which is the real owner of the concrete runtime file state model.

### Interface

```moonbit
pub using @file_model { type RuntimeFileState }
```

#### output

- `RuntimeFileState` - Public combined runtime snapshot containing a `file` snapshot plus queue metadata such as `queued`, `pending_count`, and `dropped_count`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This root surface is a re-export, not the concrete owner definition.
- The concrete type lives in `@file_model.RuntimeFileState`, not in `@utils`.
- The current fields are `file : FileSinkState`, `queued : Bool`, `pending_count : Int`, and `dropped_count : Int`.
- This type is returned by `RuntimeSink::file_runtime_state()` and by `ConfiguredLogger::file_runtime_state()` when file runtime context is available.
- It is broader than `FileSinkState` because it also reports whether queue wrapping is involved and how the queue is behaving.

### How to Use

Here are some specific examples provided.

#### When Need Combined File And Queue Diagnostics

When a direct runtime sink may wrap a file sink in a queue:
```moonbit
match sink.file_runtime_state() {
  Some(snapshot) => println(snapshot.pending_count)
  None => ()
}
```

In this example, queue backlog can be inspected alongside the embedded file state.

#### When Need A Single Exportable Runtime Snapshot

When runtime support output should include both file and queue context:
```moonbit
match sink.file_runtime_state() {
  Some(snapshot) => println(stringify_runtime_file_state(snapshot, pretty=true))
  None => ()
}
```

In this example, one typed object covers both the file snapshot and queue counters.

### Error Case

e.g.:
- `RuntimeFileState` itself does not have a runtime failure mode.

- If the runtime sink is not file-backed, `file_runtime_state()` may return `None` instead of producing this snapshot.

### Notes

1. Use this type when queued-file diagnostics matter, not just raw file status.

2. Use `runtime_file_state_to_json(...)` or `stringify_runtime_file_state(...)` when the snapshot should be exported.
