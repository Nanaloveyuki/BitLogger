---
name: console-sink
group: api
category: sink
update-time: 20260520
description: Create the built-in plain console sink for synchronous loggers.
key-word:
    - sink
    - console
    - sync
    - public
---

## Console-sink

Create the built-in plain console sink. This is the minimal terminal output sink commonly passed to `Logger::new(...)`.

### Interface

```moonbit
pub fn console_sink() -> ConsoleSink {
```

#### output

- `ConsoleSink` - Sink that writes records to the console using default text formatting.

### Explanation

Detailed rules explaining key parameters and behaviors

- This sink writes formatted text to the console.
- It is the simplest built-in sink for direct synchronous logging.
- Use other sink constructors when JSON, custom text formatting, callbacks, routing, or buffering are needed.

### How to Use

Here are some specific examples provided.

#### When Need Minimal Console Output

When a logger only needs default terminal output:
```moonbit
let logger = Logger::new(console_sink(), target="app")
logger.info("ready")
```

In this example, the logger writes directly to the console sink.

### Error Case

e.g.:
- If richer formatting or routing is required, this sink may be too minimal and another sink constructor should be used.

- Console output behavior still depends on the current runtime environment.

### Notes

1. This is the most common sink constructor for simple sync examples.

2. Use `json_console_sink()` or `text_console_sink(...)` when output shape matters more explicitly.
