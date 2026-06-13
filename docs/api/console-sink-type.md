---
name: console-sink-type
group: api
category: sink
update-time: 20260613
description: Public plain console sink type used for default text console output.
key-word:
    - sink
    - console
    - type
    - public
---

## Console-sink-type

`ConsoleSink` is the public plain console sink type used for default text console output. It is the minimal built-in synchronous sink and serves as the concrete sink type returned by `console_sink()`.

### Interface

```moonbit
pub struct ConsoleSink {
  _dummy : Unit
}
```

#### output

- `ConsoleSink` - Public synchronous sink type that writes records to the console with default text formatting.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a public root struct, not a type alias.
- The current visible field is `_dummy : Unit`, which exists only to carry the concrete sink type.
- `console_sink()` constructs this type as the simplest built-in console output path.
- `Logger[ConsoleSink]`, `LibraryLogger[ConsoleSink]`, and default logger helpers all use this concrete sink type when no richer formatting or routing layer is introduced.

### How to Use

Here are some specific examples provided.

#### When Need A Typed Plain Console Sink Value

When code should keep the concrete sink type visible:
```moonbit
let sink : ConsoleSink = console_sink()
```

In this example, the sink value stays explicit and can be passed into typed logger construction.

#### When Need A Minimal Root Logger Type

When logging should start from the simplest built-in console sink:
```moonbit
let logger : Logger[ConsoleSink] = Logger::new(console_sink(), target="app")
```

In this example, the concrete console sink type remains part of the logger type.

### Error Case

e.g.:
- `ConsoleSink` itself does not have a runtime failure mode.

- Console output still depends on the current runtime environment even though the sink type is always constructible.

### Notes

1. Use `console_sink()` when you need a value of this type.

2. Use `JsonConsoleSink` or `FormattedConsoleSink` when output shape should be more explicit than the default text path.
