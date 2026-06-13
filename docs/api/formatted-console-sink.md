---
name: formatted-console-sink
group: api
category: sink
update-time: 20260613
description: Create a console sink from a low-level RecordFormatter function.
key-word:
    - sink
    - console
    - formatter
    - public
---

## Formatted-console-sink

Create a console sink from a `RecordFormatter`. This is the low-level console output constructor for cases where code already has a record-to-string formatter function and does not want to go through `TextFormatter` first.

### Interface

```moonbit
pub fn formatted_console_sink(formatter : RecordFormatter) -> FormattedConsoleSink {
```

#### input

- `formatter : RecordFormatter` - Function used to render each record into a final string.

#### output

- `FormattedConsoleSink` - Console sink that prints the formatter output for each record.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper stores the provided formatter directly inside the sink.
- The sink prints exactly the string returned by the formatter.
- It is lower-level than `text_console_sink(...)` because it works with arbitrary `RecordFormatter` functions instead of `TextFormatter` values.
- Use it when formatting logic is already expressed as code rather than formatter configuration data.

### How to Use

Here are some specific examples provided.

#### When Need A Custom Record-to-string Console Renderer

When console output should come from a hand-written formatting function:
```moonbit
let formatter : RecordFormatter = fn(rec) { rec.level.label() + ": " + rec.message }
let logger = Logger::new(formatted_console_sink(formatter), target="fmt")
```

In this example, the sink prints exactly the custom formatter output.

#### When Already Working With RecordFormatter Values

When formatter creation already happened elsewhere and should be reused directly:
```moonbit
fn make_sink(formatter : RecordFormatter) -> FormattedConsoleSink {
  formatted_console_sink(formatter)
}
```

In this example, the low-level sink constructor avoids converting through `TextFormatter` first.

### Error Case

e.g.:
- If the formatter omits useful fields or target information, console output may become harder to interpret.

- If a configurable text formatting policy is preferred over a code-defined function, `text_console_sink(...)` is usually the better API.

### Notes

1. Use this helper when the formatter is already a `RecordFormatter`.

2. Use `text_console_sink(...)` when the source formatting policy is a `TextFormatter` value.
