---
name: file-sink-state
group: api
category: runtime
update-time: 20260707
description: Public file state type re-exported from file_model for live file-sink snapshots and runtime diagnostics.
key-word:
    - file
    - state
    - alias
    - public
---

## File-sink-state

`FileSinkState` is the public snapshot object used to describe the current state of a file sink. On the root `src` facade, it is re-exported from `src/file_model`, which is the real owner of the concrete file state model.

### Interface

```moonbit
pub using @file_model { type FileSinkState }
```

#### output

- `FileSinkState` - Public file state snapshot containing path, availability, policy flags, optional rotation, and failure counters.

### Explanation

Detailed rules explaining key parameters and behaviors

- This root surface is a re-export, not the concrete owner definition.
- The concrete type lives in `@file_model.FileSinkState`, not in `@utils`.
- The current snapshot fields are `path`, `available`, `append`, `auto_flush`, `rotation`, `open_failures`, `write_failures`, `flush_failures`, and `rotation_failures`.
- `rotation_failures` records how many rotation attempts failed to complete critical remove/rename/reopen steps; it is not a full file-health or backup-integrity audit.
- `FileSink::state()` returns this object directly for a concrete file sink.
- `RuntimeSink::file_state()` also returns this type, including fallback snapshots for non-file runtime sinks.
- `ConfiguredLogger::file_state()` returns the same snapshot type through the config-built runtime wrapper.

### How to Use

Here are some specific examples provided.

#### When Need A One-shot File Health Snapshot

When file runtime diagnostics should be read as one object:
```moonbit
let state = sink.state()
```

In this example, availability, policy, and failure counters are captured together.

#### When Need To Export File Diagnostics

When a snapshot should be serialized for logs or support output:
```moonbit
println(stringify_file_sink_state(runtime.file_state(), pretty=true))
```

In this example, the typed snapshot becomes readable JSON without manual field assembly.

### Error Case

e.g.:
- `FileSinkState` itself does not have a runtime failure mode.

- If the sink is unavailable, the snapshot still exists and reports `available=false` together with the current counters.

### Notes

1. Use this object for one-shot file diagnostics instead of many narrow reads.

2. Use `RuntimeFileState` when queue-related file runtime context is also required.
