---
name: formatted-callback-sink-type
group: api
category: sink
update-time: 20260613
description: Public formatted callback sink type used for RecordFormatter-driven text delivery to user callbacks.
key-word:
    - sink
    - callback
    - formatter
    - public
---

## Formatted-callback-sink-type

`FormattedCallbackSink` is the public callback sink type used for formatter-driven text delivery. It is the concrete sink type returned by both `formatted_callback_sink(...)` and `text_callback_sink(...)`, and it stores the rendering function and the string callback used for each record.

### Interface

```moonbit
pub struct FormattedCallbackSink {
  formatter : RecordFormatter
  callback : (String) -> Unit
}
```

#### output

- `FormattedCallbackSink` - Public synchronous sink type that renders each record through a stored formatter and forwards the text to a stored callback.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current fields are `formatter : RecordFormatter` and `callback : (String) -> Unit`.
- `formatted_callback_sink(...)` constructs this type directly from a formatter function and string callback.
- `text_callback_sink(...)` also returns this same type after adapting a `TextFormatter` into a `RecordFormatter`.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Formatter-driven Callback Sink Value

When code should keep the concrete rendered-text callback sink type visible:
```moonbit
let sink : FormattedCallbackSink = formatted_callback_sink(fn(rec) { rec.message }, fn(line) { println(line) })
```

In this example, the sink value stays explicit and preserves the formatter-driven text delivery path.

#### When Need A Typed Text-callback Logger

When logging should preserve the rendered-text callback sink type in the logger:
```moonbit
let logger : Logger[FormattedCallbackSink] = Logger::new(
  text_callback_sink(text_formatter(show_timestamp=false), fn(line) { println(line) }),
)
```

In this example, the concrete formatted callback sink remains part of the logger type.

### Error Case

e.g.:
- `FormattedCallbackSink` itself does not have a runtime failure mode.

- Output readability, callback behavior, and runtime cost still depend on the stored formatter and callback functions.

### Notes

1. Use `formatted_callback_sink(...)` or `text_callback_sink(...)` when you need a value of this type.

2. Use `CallbackSink` when the destination should receive full `Record` values instead of rendered text.
