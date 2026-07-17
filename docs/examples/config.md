# Configuration-Driven Logging

Use configuration when deployment should select levels, output, formatting, or queue behavior without changing application code.

## Parse, Build, Then Log

```moonbit
let raw = "{\"min_level\":\"info\",\"target\":\"service\",\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"separator\":\" | \"}},\"queue\":{\"max_pending\":64,\"overflow\":\"DropOldest\"}}"

let config = @log.parse_logger_config_text(raw) catch {
  err => {
    ignore(err)
    println("invalid logger configuration")
    return
  }
}

let logger = @log.build_logger(config)
logger.info("configured logger ready")
ignore(logger.flush())
```

Parsing validates the data before runtime construction. Keep the raw configuration outside application code in a real deployment, but handle parsing errors at the boundary where configuration enters the process.

## Run The Repository Example

```bash
moon run examples/config_build
```

## Next Steps

- Use [Queueing](../extend/queue.md) to choose overflow behavior deliberately.
- Use [Async lifecycle](./async.md) when the queue needs a background worker.
- Reference: [`parse_logger_config_text(...)`](../api/parse-logger-config-text.md), [`build_logger(...)`](../api/build-logger.md), and [`with_queue(...)`](../api/with-queue.md).
