---
name: runtime-sink-progress
group: api
category: runtime
update-time: 20260707
description: Public structured generic progress snapshot used by RuntimeSink and ConfiguredLogger flush or drain helpers.
key-word:
    - runtime
    - progress
    - flush
    - public
---

## Runtime-sink-progress

`RuntimeSinkProgress` is the public structured progress snapshot returned by the truthful generic `flush_progress(...)` and `drain_progress(...)` helpers. It separates queue advancement from plain file flush fallback steps so callers do not have to infer mixed `Int` semantics from `flush()` or `drain()` alone.

### Interface

```moonbit
pub struct RuntimeSinkProgress {
  queue_advanced_count : Int
  file_flush_step_count : Int
  queue_backed : Bool
  file_backed : Bool
}
```

#### output

- `RuntimeSinkProgress` - Public generic progress snapshot containing queue advancement count, plain-file flush fallback count, and runtime-shape flags.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- `queue_advanced_count` reports how many queued records were consumed by a queue-backed runtime helper call.
- `file_flush_step_count` reports the plain-file fallback step count used by generic helpers on non-queued file sinks, currently `1` for a successful `FileSink::flush()` and `0` otherwise.
- `queue_backed` reports whether the runtime sink shape was queue-backed during the helper call.
- `file_backed` reports whether the runtime sink shape was file-backed during the helper call.
- For queued file sinks, `queue_advanced_count` may be positive while `file_flush_step_count` stays `0`; delayed file failures still belong to `file_flush()` and failure-counter inspection rather than to this generic progress snapshot.

### How to Use

Here are some specific examples provided.

#### When Need Truthful Generic Runtime Progress

When code should inspect generic flush or drain work without guessing what one `Int` means:
```moonbit
let progress = sink.flush_progress()
if progress.queue_backed {
  println(progress.queue_advanced_count)
}
```

In this example, queue progress stays explicit instead of being folded into a compatibility count.

#### When Need To Distinguish Plain File Fallback From Queue Work

When generic runtime support code should tell plain-file fallback apart from queued advancement:
```moonbit
let progress = logger.drain_progress()
if progress.file_backed && !progress.queue_backed {
  println(progress.file_flush_step_count)
}
```

In this example, the caller can recognize the plain-file generic fallback path directly.

### Error Case

e.g.:
- `RuntimeSinkProgress` itself does not have a runtime failure mode.

- This type reports generic progress only; it does not prove durable file delivery.

- If callers need file-specific success semantics, `file_flush()` is still the narrower API.

### Notes

1. Prefer this structured result over the legacy `Int` returned by `flush()` and `drain()` when new code can choose.

2. For queued file sinks, combine this snapshot with `file_flush()`, `file_runtime_state()`, or file failure counters when file outcome matters.
