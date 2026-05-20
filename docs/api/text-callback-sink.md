---
name: text-callback-sink
group: api
category: sink
update-time: 20260520
description: Create a callback sink that forwards rendered text using a TextFormatter.
key-word:
    - sink
    - callback
    - text
    - public
---

## Text-callback-sink

Create a callback sink that renders each record with a `TextFormatter` and forwards the resulting string to a callback. This is useful when integrations need formatted text without writing to the console directly.

### Interface

```moonbit
pub fn text_callback_sink(
  formatter : TextFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
```

#### input

- `formatter : TextFormatter` - Formatter used to render each record.
- `callback : (String) -> Unit` - Function receiving the rendered text.

#### output

- `FormattedCallbackSink` - Callback sink working on rendered text.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper combines text rendering and callback delivery in one sink.
- It is the text-oriented counterpart to `callback_sink(...)`.
- Use it when a custom destination needs the final rendered text rather than the structured record object.

### How to Use

Here are some specific examples provided.

#### When Need Rendered Text In A Custom Integration

When a callback destination wants the final human-readable line:
```moonbit
let sink = text_callback_sink(
  text_formatter(show_timestamp=false),
  fn(line) {
    println(line)
  },
)
```

In this example, the callback receives rendered text instead of a `Record`.

### Error Case

e.g.:
- If structured field access is needed, use `callback_sink(...)` instead.

- Callback failures are outside the sink's own API contract.

### Notes

1. This helper is useful for tests and adapters that want human-readable output.

2. `formatted_callback_sink(...)` is the lower-level variant when the formatter input is already a `RecordFormatter`.
