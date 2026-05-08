# BitLogger

BitLogger is a structured logging library written in MoonBit.

## Overview

BitLogger currently provides:

- log levels: `Trace`, `Debug`, `Info`, `Warn`, `Error`
- structured key-value fields
- plain console output
- JSON console output
- child target composition via `child(...)`
- context fields via `with_context_fields(...)`
- optional timestamps via `with_timestamp()`
- sink fanout via `fanout_sink(...)`
- custom integration via `callback_sink(...)`
- default global logger helpers

## Quick Start

```moonbit
let logger = Logger::new(console_sink(), min_level=Level::Info, target="demo")
  .with_timestamp()
  .with_context_fields([field("service", "bitlogger")])

logger.info("starting", fields=[field("port", "8080")])
```

Child target composition:

```moonbit
let worker = Logger::new(console_sink(), target="app").child("worker")
worker.info("job ready")
```

Custom callback sink:

```moonbit
let hook = Logger::new(
  callback_sink(fn(rec) {
    println("callback saw [\{rec.target}] \{rec.message}")
  }),
  target="hook",
)

hook.info("hello")
```

## Repository Layout

- `bitlogger/`: MoonBit library package, tests, and Mooncake package README
- `examples/basic/`: runnable example package

## Links

- [Mooncake package page](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [Chinese README](../README.md)
