---
name: file-sink-policy
group: api
category: sink
update-time: 20260707
description: Public file policy type re-exported from file_model for file and runtime control APIs.
key-word:
    - file
    - policy
    - alias
    - public
---

## File-sink-policy

`FileSinkPolicy` is the public policy object used to describe file append mode, auto-flush behavior, and optional rotation settings together. On the root `src` facade, it is re-exported from `src/file_model`, which is the real owner of the concrete policy model.

### Interface

```moonbit
pub using @file_model { type FileSinkPolicy }
```

#### output

- `FileSinkPolicy` - Public file policy object containing `append`, `auto_flush`, and optional `rotation` settings.

### Explanation

Detailed rules explaining key parameters and behaviors

- This root surface is a re-export, not the concrete owner definition.
- The concrete type lives in `@file_model.FileSinkPolicy`, not in `@utils`.
- The current policy fields are `append : Bool`, `auto_flush : Bool`, and `rotation : FileRotation?`.
- The same policy object is returned by `FileSink::policy()`, `RuntimeSink::file_policy()`, and `ConfiguredLogger::file_policy()`.
- It is also accepted by `FileSink::set_policy(...)`, `RuntimeSink::file_set_policy(...)`, and `ConfiguredLogger::file_set_policy(...)`.

### How to Use

Here are some specific examples provided.

#### When Need One Object For Runtime File Settings

When append, flush, and rotation behavior should be updated together:
```moonbit
let policy = FileSinkPolicy::new(
  append=false,
  auto_flush=true,
  rotation=Some(file_rotation(1024 * 1024, max_backups=3)),
)
```

In this example, the file policy can be passed around as one typed value instead of separate flags.

#### When Need Runtime Policy Roundtrip

When current file behavior should be read, adjusted, and written back:
```moonbit
let policy = runtime.file_policy()
let next = FileSinkPolicy::new(
  append=policy.append,
  auto_flush=false,
  rotation=policy.rotation,
)
```

In this example, the policy object is the handoff boundary for direct runtime file control.

### Error Case

e.g.:
- `FileSinkPolicy` itself does not have a runtime failure mode.

- If a non-file runtime sink exposes a fallback policy through file helpers, the object is still valid but does not reflect a live file handle.

### Notes

1. Use `FileSinkPolicy::new(...)` to construct this policy explicitly.

2. Use `file_sink_policy_to_json(...)` or `stringify_file_sink_policy(...)` when the policy should be exported.
