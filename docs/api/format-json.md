---
name: format-json
group: api
category: formatter
update-time: 20260613
description: Render a Record into compact JSON text for machine-readable logging output.
key-word:
    - format
    - json
    - record
    - public
---

## Format-json

Render a `Record` into compact JSON text. This helper is the direct structured-output path used by JSON-oriented logging workflows when you want machine-readable serialization without building a sink.

### Interface

```moonbit
pub fn format_json(rec : Record) -> String {
```

#### input

- `rec : Record` - Log record to serialize.

#### output

- `String` - Compact JSON text built from the record contents.

### Explanation

Detailed rules explaining key parameters and behaviors

- The output always includes `level`, `message`, and `fields`.
- `timestamp_ms` is only included when `rec.timestamp_ms != 0`.
- `target` is only included when `rec.target` is not empty.
- The result is compact JSON text rather than pretty-printed output.
- Field values are serialized through the record's structured field array instead of reparsing formatted text.

### How to Use

Here are some specific examples provided.

#### When Need Machine-readable Output In Tests Or Adapters

When record data should be passed along as structured JSON text:
```moonbit
let rec = Record::new(Level::Info, "ready", fields=[field("service", "api")])
println(format_json(rec))
```

In this example, the returned string can be consumed by JSON-aware tooling.

#### When Need Structured Output Without A Json Sink Instance

When a callback or bridge already has a `Record` and only needs serialization:
```moonbit
let callback = fn(rec : Record) {
  let payload = format_json(rec)
  println(payload)
}
```

In this example, the code reuses the built-in JSON record shape directly.

### Error Case

e.g.:
- There is no separate failure path for valid `Record` values.

- If a caller needs readable aligned text rather than JSON, `format_text(...)` is the better API.

### Notes

1. This helper returns compact JSON and does not expose a pretty-print option.

2. It is a natural companion to `json_console_sink()` for structured logging flows.
