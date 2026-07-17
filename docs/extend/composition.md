# Sink Composition

Presets cover common console and file configurations. Build a `Logger::new(...)` directly when records need routing or multiple outputs.

## Send A Record To Two Destinations

```moonbit
let logger = @log.Logger::new(
  @log.fanout_sink(@log.console_sink(), @log.json_console_sink()),
  min_level=@log.Level::Info,
  target="service",
)

logger.info("request complete", fields=[@log.field("status", "200")])
```

`fanout_sink(...)` writes the same record to every child sink. This keeps human-oriented terminal output and machine-oriented JSON output in one application path.

## Route Warnings Separately

```moonbit
let logger = @log.Logger::new(
  @log.split_by_level(
    @log.callback_sink(fn(rec) {
      println("alert: \{rec.message}")
    }),
    @log.console_sink(),
    min_level=@log.Level::Warn,
  ),
  min_level=@log.Level::Trace,
  target="service",
)
```

Use direct sink composition only when the routing behavior is part of the application design. A preset remains easier to audit when one sink is sufficient.

## API Reference

- [`Logger::new(...)`](../api/logger-new.md)
- [`fanout_sink(...)`](../api/fanout-sink.md)
- [`split_by_level(...)`](../api/split-by-level.md)
- [`callback_sink(...)`](../api/callback-sink.md)
