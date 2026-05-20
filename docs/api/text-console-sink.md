---
name: text-console-sink
group: api
category: sink
update-time: 20260520
description: Create a formatted console sink from a TextFormatter.
key-word:
    - sink
    - text
    - formatter
    - public
---

## Text-console-sink

Create a formatted console sink from a `TextFormatter`. This sink is the direct sync constructor for human-readable console output with explicit text formatting rules.

### Interface

```moonbit
pub fn text_console_sink(formatter : TextFormatter) -> FormattedConsoleSink {
```

#### input

- `formatter : TextFormatter` - Text formatter used to render each record.

#### output

- `FormattedConsoleSink` - Console sink that renders through the supplied formatter.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper adapts a `TextFormatter` into a console sink.
- It is the direct sync sink counterpart to config-driven `text_console(...)` presets.
- Use it when code-side formatter composition is preferable to config-driven assembly.

### How to Use

Here are some specific examples provided.

#### When Need Explicit Text Formatting On The Console

When console output should use a custom separator or template:
```moonbit
let logger = Logger::new(
  text_console_sink(text_formatter(show_timestamp=false, separator=" | ")),
  target="pretty",
)
```

In this example, the sink renders through the supplied formatter.

### Error Case

e.g.:
- If structured JSON output is required, use `json_console_sink()` instead.

- If formatting should be data-driven rather than code-driven, prefer config or presets APIs.

### Notes

1. This is the most direct sync sink constructor for custom text output.

2. `formatted_console_sink(...)` is the lower-level variant when the formatter input is already a `RecordFormatter`.
