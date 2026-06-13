---
name: format-text
group: api
category: formatter
update-time: 20260613
description: Render a Record into human-readable text using a TextFormatter.
key-word:
    - format
    - text
    - formatter
    - public
---

## Format-text

Render a `Record` into readable text. This helper is the direct formatting path behind text-oriented sinks and custom inspection code when you want the same text rendering behavior without building a logger.

### Interface

```moonbit
pub fn format_text(rec : Record, formatter~ : TextFormatter = text_formatter()) -> String {
```

#### input

- `rec : Record` - Log record to render.
- `formatter : TextFormatter` - Formatter rules controlling timestamps, labels, fields, template behavior, color policy, and style markup.

#### output

- `String` - Rendered text for the supplied record.

### Explanation

Detailed rules explaining key parameters and behaviors

- If `formatter.template` is not empty, formatting uses the template-driven path.
- With the default assembly path, timestamp text is only included when `formatter.show_timestamp=true` and `rec.timestamp_ms != 0`.
- Target text is only included when `formatter.show_target=true` and `rec.target` is not empty.
- Field text is only appended when `formatter.show_fields=true` and the record actually has fields.
- Message, target, and field values follow the markup and color behavior carried by the supplied `TextFormatter`.

### How to Use

Here are some specific examples provided.

#### When Need Direct Text Rendering Without A Sink

When tests, adapters, or custom outputs should reuse the built-in text formatter behavior:
```moonbit
let rec = Record::new(Level::Info, "started", target="worker")
let text = format_text(rec)
```

In this example, `text` uses the default human-readable formatter settings.

#### When Need Predictable Custom Text Layout

When the output should follow explicit formatter rules:
```moonbit
let formatter = text_formatter(show_timestamp=false, separator=" | ")
let rec = Record::new(Level::Warn, "retrying", fields=[field("attempt", "2")])
println(format_text(rec, formatter=formatter))
```

In this example, the rendered line follows the supplied formatter instead of the default one.

### Error Case

e.g.:
- There is no dedicated failure path for valid `Record` and `TextFormatter` values.

- If the formatter hides timestamps, targets, or fields, the returned text omits those parts by design.

### Notes

1. Use `text_formatter(...)` to build a reusable formatter once, then pass it to repeated `format_text(...)` calls.

2. For machine-readable output, `format_json(...)` is usually a better fit.
