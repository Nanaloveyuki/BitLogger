---
name: async-logger-with-patch
group: api
category: async
update-time: 20260512
description: Attach record transformation logic to an async logger before records reach the queue.
key-word:
    - async
    - logger
    - patch
    - public
---

## Async-logger-with-patch

Attach a record patch to an async logger so each record is transformed before filtering and enqueue. This is the main API for async record rewriting without changing the sink implementation.

### Interface

```moonbit
pub fn[S] AsyncLogger::with_patch(
  self : AsyncLogger[S],
  patch : @bitlogger.RecordPatch,
) -> AsyncLogger[S] {}
```

#### input

- `self : AsyncLogger[S]` - Base async logger to wrap.
- `patch : RecordPatch` - Transformation applied to each record before enqueue.

#### output

- `AsyncLogger[S]` - A new async logger that rewrites each record before filtering and queue insertion.

### Explanation

Detailed rules explaining key parameters and behaviors

- Patch logic runs after record creation and field merging but before filtering and enqueue.
- Existing patch logic is preserved and composed so the new patch wraps the current one.
- The original async logger is not mutated.
- Patching can normalize, redact, or enrich records before they consume queue capacity.

### How to Use

Here are some specific examples provided.

#### When Need Async Record Enrichment

When records should gain stable extra data before enqueue:
```moonbit
let logger = async_logger(console_sink())
  .with_patch(@bitlogger.append_fields([
    @bitlogger.field("channel", "async"),
  ]))
```

In this example, the added fields are part of the record before filtering and queue insertion.

#### When Need Redaction Before Queueing

When sensitive fields should be removed early:
```moonbit
let logger = async_logger(console_sink())
  .with_patch(@bitlogger.redact_fields(["token", "password"]))
```

In this example, sensitive values are rewritten before they enter the async pipeline.

### Error Case

e.g.:
- If the patch removes or rewrites important data incorrectly, later filters and sinks will only see the patched version.

- If callers need selection logic rather than transformation, `with_filter(...)` should be used instead.

### Notes

1. Use patches for transformation, not filtering decisions.

2. Redaction before enqueue helps keep sensitive data out of the queued pipeline.
