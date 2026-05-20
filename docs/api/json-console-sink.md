---
name: json-console-sink
group: api
category: sink
update-time: 20260520
description: Create the built-in JSON console sink for structured synchronous logging.
key-word:
    - sink
    - json
    - console
    - public
---

## Json-console-sink

Create the built-in JSON console sink. This sink writes records as structured JSON text and is useful when stdout is consumed by machines rather than humans.

### Interface

```moonbit
pub fn json_console_sink() -> JsonConsoleSink {
```

#### output

- `JsonConsoleSink` - Sink that writes records to the console as JSON.

### Explanation

Detailed rules explaining key parameters and behaviors

- This sink emits JSON rather than human-focused text formatting.
- It is a direct synchronous sink that can be passed to `Logger::new(...)`.
- Use it when structured logs should be parsed, shipped, or inspected programmatically.

### How to Use

Here are some specific examples provided.

#### When Need Structured Stdout Logs

When log consumers expect machine-readable output:
```moonbit
let logger = Logger::new(json_console_sink(), target="api")
logger.info("ready", fields=[field("service", "bitlogger")])
```

In this example, the emitted console line is JSON-shaped.

### Error Case

e.g.:
- If human-focused text formatting is required, use a text console sink instead.

- Console output still depends on the current runtime environment.

### Notes

1. This sink is useful for structured stdout pipelines.

2. It pairs naturally with field-heavy logging.
