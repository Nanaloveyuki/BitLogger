---
name: formatted-callback-sink
group: api
category: sink
update-time: 20260613
description: Create a callback sink from a low-level RecordFormatter function and string callback.
key-word:
    - sink
    - callback
    - formatter
    - public
---

## Formatted-callback-sink

Create a callback sink from a `RecordFormatter` and a string callback. This is the low-level text-delivery constructor for integrations that already have custom record-to-string formatting logic and want the final rendered text in a callback.

### Interface

```moonbit
pub fn formatted_callback_sink(
  formatter : RecordFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
```

#### input

- `formatter : RecordFormatter` - Function used to render each record into a final string.
- `callback : (String) -> Unit` - Function receiving the rendered string.

#### output

- `FormattedCallbackSink` - Callback sink that forwards formatter output as text.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper stores both the provided formatter and callback directly inside the sink.
- The callback receives exactly the string returned by the formatter.
- It is lower-level than `text_callback_sink(...)` because it works with arbitrary `RecordFormatter` functions instead of `TextFormatter` values.
- Use it when formatting logic is already expressed as code rather than formatter configuration data.

### How to Use

Here are some specific examples provided.

#### When Need Custom Rendered Text In A Callback Integration

When an adapter should receive a hand-formatted line instead of a structured record:
```moonbit
let formatter : RecordFormatter = fn(rec) { "[" + rec.level.label() + "] " + rec.message }
let sink = formatted_callback_sink(formatter, fn(line) { println(line) })
```

In this example, the callback receives exactly the custom rendered text.

#### When Already Working With Shared RecordFormatter Values

When formatter creation already happened elsewhere and should be reused directly:
```moonbit
fn make_sink(formatter : RecordFormatter) -> FormattedCallbackSink {
  formatted_callback_sink(formatter, fn(line) { println(line) })
}
```

In this example, the low-level sink constructor keeps the integration in terms of formatter functions and final text callbacks.

### Error Case

e.g.:
- If structured field access is required inside the callback, `callback_sink(...)` is the better API because it forwards full `Record` values.

- If a configurable text formatting policy is preferred over a code-defined function, `text_callback_sink(...)` is usually the better API.

### Notes

1. Use this helper when the formatter is already a `RecordFormatter` and the destination expects final text.

2. Use `text_callback_sink(...)` when the source formatting policy is a `TextFormatter` value.
