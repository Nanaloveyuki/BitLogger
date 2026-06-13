---
name: file-sink-policy-new
group: api
category: sink
update-time: 20260613
description: Construct a FileSinkPolicy value from explicit append, auto-flush, and rotation settings.
key-word:
    - file
    - policy
    - constructor
    - public
---

## File-sink-policy-new

Construct a `FileSinkPolicy` value from explicit append, auto-flush, and rotation settings. This is the low-level constructor behind the public file policy shape used by direct file sinks and configured runtime file controls.

### Interface

```moonbit
pub fn FileSinkPolicy::new(
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
) -> FileSinkPolicy {
```

#### input

- `append : Bool` - Whether file open and reopen behavior should append instead of truncate.
- `auto_flush : Bool` - Whether each write should try to flush immediately.
- `rotation : FileRotation?` - Optional size-based rotation policy, or `None` to disable rotation.

#### output

- `FileSinkPolicy` - File policy object containing the supplied append, auto-flush, and rotation settings.

### Explanation

Detailed rules explaining key parameters and behaviors

- Omitting optional arguments uses the baseline policy: append enabled, auto-flush enabled, and no rotation.
- This constructor simply packages the supplied settings into one public policy value.
- It does not inspect or mutate a live file sink by itself.
- The resulting value matches the same public shape accepted by `FileSink::set_policy(...)` and `ConfiguredLogger::file_set_policy(...)`.

### How to Use

Here are some specific examples provided.

#### When Need A Hand-built File Policy

When append, flush, and rotation settings should be assembled as one typed value:
```moonbit
let policy = FileSinkPolicy::new(
  append=false,
  auto_flush=false,
  rotation=Some(file_rotation(2048, max_backups=2)),
)
```

In this example, the file policy is constructed directly without reading a live sink first.

#### When Need A Policy Value For Runtime Updates

When a direct or configured file sink should be updated with one cohesive policy object:
```moonbit
let policy = FileSinkPolicy::new(auto_flush=false)
```

In this example, callers create the policy once and can pass it into runtime file control APIs.

### Error Case

e.g.:
- This constructor itself does not have a normal failure mode; it only packages the provided settings.

- If callers want the current live policy from a sink instead of constructing a new one, `policy()` or `file_policy()` is the simpler API.

### Notes

1. Use this helper when code should construct a `FileSinkPolicy` value explicitly.

2. Pair it with `file_sink_policy_to_json(...)` or `stringify_file_sink_policy(...)` when the policy should be exported.
