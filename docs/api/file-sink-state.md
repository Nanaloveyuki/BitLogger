---
name: file-sink-state
group: api
category: runtime
update-time: 20260613
description: Public file state alias used for live file-sink snapshots and runtime diagnostics.
key-word:
    - file
    - state
    - alias
    - public
---

## File-sink-state

`FileSinkState` is the public snapshot object used to describe the current state of a file sink. It is a direct alias to the file state model returned by `FileSink::state()` and by higher-level runtime file inspection helpers.

### Interface

```moonbit
pub type FileSinkState = @utils.FileSinkState
```

#### output

- `FileSinkState` - Public file state snapshot containing path, availability, policy flags, optional rotation, and failure counters.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a live file handle wrapper.
- The current snapshot fields are `path`, `available`, `append`, `auto_flush`, `rotation`, `open_failures`, `write_failures`, `flush_failures`, and `rotation_failures`.
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
