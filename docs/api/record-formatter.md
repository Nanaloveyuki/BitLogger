---
name: record-formatter
group: api
category: helper
update-time: 20260613
description: Public formatter function type used to render records into strings.
key-word:
    - formatter
    - record
    - text
    - public
---

## Record-formatter

`RecordFormatter` is the public function type used for rendering a `Record` into a `String`. It is the shared shape behind helpers such as `format_text(...)`, custom formatter closures, and sinks that accept formatter functions.

### Interface

```moonbit
pub type RecordFormatter = @utils.RecordFormatter
```

#### output

- `RecordFormatter` - A function type equivalent to `(Record) -> String`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a new runtime wrapper.
- Any function matching `(Record) -> String` can be used wherever a `RecordFormatter` is expected.
- Formatter values are used by `formatted_console_sink(...)`, `formatted_callback_sink(...)`, and text-formatting helpers.
- The alias exists to make rendering-oriented APIs clearer and easier to read in public signatures.

### How to Use

Here are some specific examples provided.

#### When Need A Custom Formatting Function

When a sink should render records with custom output rules:
```moonbit
let formatter : RecordFormatter = fn(rec) { rec.level.label() + ": " + rec.message }
let sink = formatted_console_sink(formatter)
```

In this example, the alias makes the custom renderer shape explicit.

#### When Pass A Formatter Through Higher-level APIs

When application code should accept any formatter function:
```moonbit
fn make_sink(formatter : RecordFormatter) -> FormattedConsoleSink {
  formatted_console_sink(formatter)
}
```

In this example, the alias communicates that the parameter is a record-to-string renderer.

### Error Case

e.g.:
- A formatter that omits important fields or level information can make output harder to interpret.

- A formatter that performs heavy work on every record can add noticeable runtime cost.

### Notes

1. Use the alias when function signatures should communicate rendering intent clearly.

2. `text_formatter(...)` plus `format_text(...)` is usually the better default for configurable human-readable output.
