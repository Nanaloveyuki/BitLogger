---
name: runtime-file-state-new
group: api
category: runtime
update-time: 20260613
description: Construct a RuntimeFileState snapshot from explicit file state and queue-runtime values.
key-word:
    - runtime
    - file
    - state
    - public
---

## Runtime-file-state-new

Construct a `RuntimeFileState` snapshot from explicit file state and queue-runtime values. This is the low-level constructor behind the public combined file-and-queue runtime state shape used in diagnostics.

### Interface

```moonbit
pub fn RuntimeFileState::new(
  file : FileSinkState,
  queued~ : Bool = false,
  pending_count~ : Int = 0,
  dropped_count~ : Int = 0,
) -> RuntimeFileState {
```

#### input

- `file : FileSinkState` - Embedded file sink snapshot.
- `queued : Bool` - Whether queue wrapping is involved for the runtime file sink.
- `pending_count : Int` - Current queued backlog count.
- `dropped_count : Int` - Current dropped-record count.

#### output

- `RuntimeFileState` - Combined runtime snapshot containing the supplied file snapshot plus queue metadata.

### Explanation

Detailed rules explaining key parameters and behaviors

- Omitting optional arguments builds a non-queued baseline around the supplied file snapshot.
- This constructor simply packages the supplied fields into one public runtime snapshot value.
- It does not inspect a live configured logger by itself.
- `ConfiguredLogger::file_runtime_state()` is the higher-level API that reads these values from concrete runtime objects.

### How to Use

Here are some specific examples provided.

#### When Need A Hand-built Combined File And Queue Snapshot

When tests or adapters should construct runtime file diagnostics explicitly:
```moonbit
let snapshot = RuntimeFileState::new(
  FileSinkState::new("app.log", available=true),
  queued=true,
  pending_count=3,
  dropped_count=1,
)
```

In this example, the runtime file snapshot is built directly without querying a live configured logger.

#### When Need Structured Runtime Diagnostics Input Before Serialization

When code should prepare a typed runtime file state value for later export:
```moonbit
let snapshot = RuntimeFileState::new(
  logger.file_state(),
  queued=true,
  pending_count=logger.pending_count(),
  dropped_count=logger.dropped_count(),
)
```

In this example, callers still use the direct constructor while making each queue-related input explicit.

### Error Case

e.g.:
- This constructor itself does not have a normal failure mode; it only packages the provided values.

- If callers want a snapshot directly from a live configured logger, `file_runtime_state()` is the simpler API.

### Notes

1. Use this helper when code should construct a `RuntimeFileState` value explicitly.

2. Pair it with `runtime_file_state_to_json(...)` or `stringify_runtime_file_state(...)` when the snapshot should be exported.
