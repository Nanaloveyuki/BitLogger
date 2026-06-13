---
name: file-sink-state-new
group: api
category: runtime
update-time: 20260613
description: Construct a FileSinkState snapshot from explicit file availability, policy, and failure-counter values.
key-word:
    - file
    - state
    - diagnostics
    - public
---

## File-sink-state-new

Construct a `FileSinkState` snapshot from explicit file availability, policy, and failure-counter values. This is the low-level constructor behind the public file sink state shape used in diagnostics.

### Interface

```moonbit
pub fn FileSinkState::new(
  path : String,
  available~ : Bool = false,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  open_failures~ : Int = 0,
  write_failures~ : Int = 0,
  flush_failures~ : Int = 0,
  rotation_failures~ : Int = 0,
) -> FileSinkState {
```

#### input

- `path : String` - File path represented by the snapshot.
- `available : Bool` - Whether the file sink currently reports an available file handle.
- `append : Bool` - Current append-mode policy.
- `auto_flush : Bool` - Current auto-flush policy.
- `rotation : FileRotation?` - Current optional rotation policy.
- `open_failures : Int` - Current open-failure counter.
- `write_failures : Int` - Current write-failure counter.
- `flush_failures : Int` - Current flush-failure counter.
- `rotation_failures : Int` - Current rotation-failure counter.

#### output

- `FileSinkState` - File sink snapshot containing the supplied path, availability, policy, and failure-counter values.

### Explanation

Detailed rules explaining key parameters and behaviors

- Omitting optional arguments uses a conservative baseline snapshot: unavailable, append enabled, auto-flush enabled, no rotation, and zeroed counters.
- This constructor simply packages the supplied fields into one public snapshot value.
- It does not inspect a live `FileSink` by itself.
- `FileSink::state()` and `ConfiguredLogger::file_state()` are the higher-level APIs that read these values from concrete runtime objects.

### How to Use

Here are some specific examples provided.

#### When Need A Hand-built File State Snapshot

When tests or adapters should construct file diagnostics explicitly:
```moonbit
let state = FileSinkState::new(
  "app.log",
  available=true,
  append=false,
  auto_flush=false,
  rotation=Some(file_rotation(2048, max_backups=2)),
)
```

In this example, the file state snapshot is built directly without querying a live sink.

#### When Need Structured Diagnostics Input Before Serialization

When code should prepare a typed file state value for later export:
```moonbit
let state = FileSinkState::new(
  sink.path(),
  available=sink.is_available(),
  append=sink.append_mode(),
  auto_flush=sink.auto_flush_enabled(),
  rotation=sink.rotation_config(),
  open_failures=sink.open_failures(),
  write_failures=sink.write_failures(),
  flush_failures=sink.flush_failures(),
  rotation_failures=sink.rotation_failures(),
)
```

In this example, callers still use the direct constructor while making each diagnostic input explicit.

### Error Case

e.g.:
- This constructor itself does not have a normal failure mode; it only packages the provided values.

- If callers want a snapshot directly from a live file sink or configured logger, `state()` or `file_state()` is the simpler API.

### Notes

1. Use this helper when code should construct a `FileSinkState` value explicitly.

2. Pair it with `file_sink_state_to_json(...)` or `stringify_file_sink_state(...)` when the snapshot should be exported.
