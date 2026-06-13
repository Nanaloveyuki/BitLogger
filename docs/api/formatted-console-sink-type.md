---
name: formatted-console-sink-type
group: api
category: sink
update-time: 20260613
description: Public formatted console sink type used for RecordFormatter-driven synchronous console output.
key-word:
    - sink
    - console
    - formatter
    - public
---

## Formatted-console-sink-type

`FormattedConsoleSink` is the public console sink type used for formatter-driven text output. It is the concrete sink type returned by both `formatted_console_sink(...)` and `text_console_sink(...)`, and it stores the rendering function used for each record.

### Interface

```moonbit
pub struct FormattedConsoleSink {
  formatter : RecordFormatter
}
```

#### output

- `FormattedConsoleSink` - Public synchronous sink type that renders each record through a stored `RecordFormatter`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current field is `formatter : RecordFormatter`.
- `formatted_console_sink(...)` constructs this type directly from a formatter function.
- `text_console_sink(...)` also returns this same type after adapting a `TextFormatter` into a `RecordFormatter`.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Formatter-driven Console Sink Value

When code should keep the concrete formatted sink type visible:
```moonbit
let sink : FormattedConsoleSink = formatted_console_sink(fn(rec) { rec.message })
```

In this example, the sink value keeps the low-level formatter-driven console type explicit.

#### When Need A Typed Text-formatted Console Logger

When logging should preserve the formatter-backed console sink type in the logger:
```moonbit
let logger : Logger[FormattedConsoleSink] = Logger::new(
  text_console_sink(text_formatter(show_timestamp=false)),
  target="pretty",
)
```

In this example, the concrete formatted console sink remains part of the logger type.

### Error Case

e.g.:
- `FormattedConsoleSink` itself does not have a runtime failure mode.

- Output readability and cost still depend on the stored formatter function and its behavior.

### Notes

1. Use `formatted_console_sink(...)` or `text_console_sink(...)` when you need a value of this type.

2. Use `ConsoleSink` or `JsonConsoleSink` when default text or JSON output is enough and a stored formatter function is unnecessary.
