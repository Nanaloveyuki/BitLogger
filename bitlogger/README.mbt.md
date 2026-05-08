# BitLogger

BitLogger is a minimal structured logger for MoonBit.

BitLogger 是一个基于 MoonBit 的结构化日志库。

## Features / 特性

- log levels: `Trace`, `Debug`, `Info`, `Warn`, `Error`
- 日志级别：`Trace`、`Debug`、`Info`、`Warn`、`Error`
- structured key-value fields
- 结构化字段：`field("key", "value")`
- sink abstraction
- sink 抽象与组合边界
- default global console logger
- 默认全局 logger 辅助函数
- context fields via `with_context_fields(...)`
- 通过 `with_context_fields(...)` 添加上下文字段
- child target composition via `child(...)`
- 通过 `child(...)` 组合层级 target
- optional timestamps via `with_timestamp()`
- 通过 `with_timestamp()` 启用时间戳
- JSON console output via `json_console_sink()`
- `json_console_sink()` 提供 JSON 控制台输出
- sink composition via `fanout_sink(...)`
- `fanout_sink(...)` 支持多 sink 组合
- custom callback sink via `callback_sink(...)`
- `callback_sink(...)` 支持自定义外部集成

## Example / 示例

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

```mbt check
test {
  let logger = Logger::new(console_sink(), target="app").child("worker")
  logger.info("ready")
}
```

```mbt check
test {
  let logger = Logger::new(
    callback_sink(fn(rec) {
      println("callback saw [\{rec.target}] \{rec.message}")
    }),
    target="hook",
  )
  logger.info("hello")
}
```

