---
name: runtime-sink
group: api
category: runtime
update-time: 20260613
description: Public runtime sink enum used by config-built synchronous loggers to unify console, file, and queued sink variants.
key-word:
    - runtime
    - sink
    - type
    - public
---

## Runtime-sink

`RuntimeSink` is the public runtime sink enum used by config-built synchronous loggers. It unifies console, file, and queued sink variants behind one runtime-facing sink surface.

### Interface

```moonbit
pub(all) enum RuntimeSink {
  Console(ConsoleSink)
  JsonConsole(JsonConsoleSink)
  TextConsole(FormattedConsoleSink)
  File(FileSink)
  QueuedConsole(QueuedSink[ConsoleSink])
  QueuedJsonConsole(QueuedSink[JsonConsoleSink])
  QueuedTextConsole(QueuedSink[FormattedConsoleSink])
  QueuedFile(QueuedSink[FileSink])
}
```

#### output

- `RuntimeSink` - Public runtime sink union used by `ConfiguredLogger` and config-built logging helpers.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public enum root type, not a type alias.
- The variants cover plain console sinks, plain file sinks, and queue-wrapped forms of those sink families.
- `build_logger(...)` and related config-driven construction paths use this type as the concrete sink behind `ConfiguredLogger`.
- The type exposes direct runtime helpers such as `flush()`, `drain()`, `close()`, `pending_count()`, and `dropped_count()`.
- Queue-specific metrics are meaningful only for queued variants, while plain variants usually report `0` for queue counters.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Config-built Runtime Sink Surface

When code should keep the runtime sink union explicit after config assembly:
```moonbit
let logger = build_logger(LoggerConfig::new(target="svc"))
let sink : RuntimeSink = logger.sink
```

In this example, the concrete runtime sink remains available for direct runtime inspection.

#### When Need Direct Runtime Variant-specific Branching

When behavior should differ between plain and queued runtime sink variants:
```moonbit
match sink {
  QueuedFile(inner) => ignore(inner.pending_count())
  File(inner) => ignore(inner.is_available())
  _ => ()
}
```

In this example, the enum shape makes runtime sink-specific handling explicit.

### Error Case

e.g.:
- `RuntimeSink` itself does not have a runtime failure mode.

- Actual file behavior, queue backlog, and close results still depend on the active variant and current backend state.

### Notes

1. `ConfiguredLogger` is the main higher-level alias that wraps `Logger[RuntimeSink]`.

2. Use the direct `RuntimeSink` helpers when code owns the sink value itself instead of only the logger wrapper.
