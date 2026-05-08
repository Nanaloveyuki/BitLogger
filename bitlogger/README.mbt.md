# BitLogger

BitLogger is a minimal structured logger for MoonBit.

## Features

- log levels: `Trace`, `Debug`, `Info`, `Warn`, `Error`
- structured key-value fields
- sink abstraction
- default global console logger
- context fields via `with_context_fields(...)`
- child target composition via `child(...)`
- optional timestamps via `with_timestamp()`
- JSON console output via `json_console_sink()`
- sink composition via `fanout_sink(...)`
- custom callback sink via `callback_sink(...)`

## Example

```mbt check
test {
  let logger = Logger::new(console_sink(), min_level=Level::Debug, target="demo")
    .with_timestamp()
  logger.info("starting", fields=[field("port", "8080")])
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="app").child("worker")
  logger.info("ready")
}
```

```mbt check
test {
  let logger = Logger::new(
    fanout_sink(console_sink(), json_console_sink()),
    min_level=Level::Info,
    target="demo",
  )
  logger.info("ready", fields=[field("mode", "fanout")])
}
```

## Notes

Current MVP includes plain-text output, JSON console output, context fields, child target composition, and simple sink fanout.
The intended public entry points are `Logger`, sink constructor helpers, `field(...)`, and the default global logger helpers.
Next useful steps are file sink and buffered or async delivery.
