# Async Logger Lifecycle

Use the async package when a native application needs logging to run through an async queue. The library supports broader targets, but the shipped `async fn main` example is native-focused.

## Import Both Packages

```moonbit
import {
  "Nanaloveyuki/BitLogger/src" @log,
  "Nanaloveyuki/BitLogger/src-async" @async_log,
  "moonbitlang/async",
}
```

## Build, Run, Then Shut Down

```moonbit
async fn main {
  let raw = "{\"logger\":{\"min_level\":\"info\",\"target\":\"service.async\",\"sink\":{\"kind\":\"text_console\"}},\"async_config\":{\"max_pending\":64,\"overflow\":\"DropOldest\",\"max_batch\":16,\"linger_ms\":5,\"flush\":\"Batch\"}}"
  let config = @async_log.parse_async_logger_build_config_text(raw) catch {
    err => {
      ignore(err)
      return
    }
  }
  let logger = @async_log.build_async_logger(config)

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    logger.info("worker started", fields=[@log.field("mode", "async")])
    logger.shutdown()
  })
}
```

`run()` owns the worker loop. Start it before producing records, then call `shutdown()` so pending work can follow the configured flush policy.

## Run The Repository Example

```bash
moon run examples/async_basic --target native
```

## Next Steps

- Inspect queue policy and flush choices in [Queueing](../extend/queue.md).
- Reference: [`parse_async_logger_build_config_text(...)`](../api/parse-async-logger-build-config-text.md), [`build_async_logger(...)`](../api/build-async-logger.md), [`run()`](../api/async-logger-run.md), and [`shutdown()`](../api/async-logger-shutdown.md).
