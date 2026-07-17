# Sink 组合

Preset 覆盖常见的控制台和文件配置。只有当记录需要路由或多个输出目的地时，才直接构造 `Logger::new(...)`。

## 同时发送到两个目的地

```moonbit
let logger = @log.Logger::new(
  @log.fanout_sink(@log.console_sink(), @log.json_console_sink()),
  min_level=@log.Level::Info,
  target="service",
)

logger.info("request complete", fields=[@log.field("status", "200")])
```

`fanout_sink(...)` 将同一记录写入每个子 Sink，因此应用可以同时保留面向人的控制台输出和面向采集器的 JSON 输出。

## 单独处理警告以上日志

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

只有当路由规则属于应用设计时才使用直接 Sink 组合；单一输出时，preset 更容易审查和维护。

## 英文 API

- [`Logger::new(...)`](../../api/logger-new.md)
- [`fanout_sink(...)`](../../api/fanout-sink.md)
- [`split_by_level(...)`](../../api/split-by-level.md)
- [`callback_sink(...)`](../../api/callback-sink.md)
