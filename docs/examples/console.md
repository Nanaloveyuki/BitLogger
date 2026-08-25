# Console And Structured Fields

Use this flow for command-line tools and services that need a human-readable starting point. A record always has a level, target, message, and optional fields.

## Install And Import

```bash
moon add Nanaloveyuki/BitLogger@0.8.1
```

```moonbit
import {
  "Nanaloveyuki/BitLogger/src" @log,
}
```

## Build A Console Logger

```moonbit
fn main {
  let logger = @log.build_logger(
    @log.console(min_level=@log.Level::Info, target="service.http"),
  )

  logger.info("listening", fields=[
    @log.field("port", "8080"),
    @log.field("environment", "development"),
  ])
  logger.warn("slow request", fields=[@log.field("path", "/health")])
}
```

`min_level` filters records before they reach the sink. `target` identifies the subsystem, while fields carry queryable context without interpolating it into the message.

## Switch To JSON

Keep the logging calls unchanged and replace the preset:

```moonbit
let logger = @log.build_logger(
  @log.json_console(min_level=@log.Level::Info, target="service.http"),
)
```

This is the preferred output for a collector that consumes one structured record per line.

## Next Steps

- Use [Text formatting](../extend/formatting.md) for a custom terminal format.
- Use [Configuration](./config.md) when levels, targets, and sinks come from JSON.
- Reference: [`console(...)`](../api/console.md), [`json_console(...)`](../api/json-console.md), [`field(...)`](../api/field.md), and [`build_logger(...)`](../api/build-logger.md).
