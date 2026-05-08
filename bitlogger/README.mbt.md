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
- buffered sink via `buffered_sink(...)`
- `buffered_sink(...)` 支持内存缓冲与 flush
- filter sink via `filter_sink(...)`
- `filter_sink(...)` 支持按 `Record` 条件筛选输出
- reusable filter helpers such as `target_has_prefix(...)`, `message_contains(...)`, and `field_equals(...)`
- 提供 `target_has_prefix(...)`、`message_contains(...)`、`field_equals(...)` 等可复用过滤辅助函数
- record patching via `with_patch(...)` and `patch_sink(...)`
- 支持 `with_patch(...)`、`patch_sink(...)` 以及常见 record patch helper
- explicit queued delivery via `queued_sink(...)` and `with_queue(...)`
- 支持 `queued_sink(...)`、`with_queue(...)`、有界积压与溢出策略
- configurable text formatting via `text_formatter(...)`, `format_text(...)`, and `text_console_sink(...)`
- 支持 `text_formatter(...)`、`format_text(...)`、`text_console_sink(...)` 等文本格式化能力
- native-only file output via `file_sink(...)`
- 支持 `file_sink(...)`，但当前仅保证 `native/llvm` backend 可用

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
  let logger = Logger::new(
    callback_sink(fn(rec) {
      println("callback saw [\{rec.target}] \{rec.message}")
    }),
    target="hook",
  )
  logger.info("hello")
}
```

```mbt check
test {
  let sink = buffered_sink(console_sink(), flush_limit=2)
  let logger = Logger::new(sink, target="buffered")
  logger.info("one")
  logger.info("two")
  sink.flush()
}
```

```mbt check
test {
  let sink = filter_sink(console_sink(), fn(rec) {
    rec.target == "kept"
  })
  let kept = Logger::new(sink, target="kept")
  let dropped = Logger::new(sink, target="dropped")
  kept.info("visible")
  dropped.info("hidden")
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="service")
    .with_filter(all_of([
      target_has_prefix("service"),
      message_contains("visible"),
    ]))
  logger.info("hidden")
  logger.child("api").info("visible")
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="auth")
    .with_patch(compose_patches([
      prefix_message("[safe] "),
      redact_fields(["token"]),
      append_fields([field("service", "bitlogger")]),
    ]))
  logger.info("login", fields=[field("user", "alice"), field("token", "secret")])
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="queue")
    .with_queue(max_pending=2, overflow=QueueOverflowPolicy::DropOldest)
  logger.info("one")
  logger.info("two")
  logger.info("three")
  ignore(logger.sink.flush())
}
```

```mbt check
test {
  let formatter = text_formatter(show_timestamp=false, separator=" | ")
  let logger = Logger::new(text_console_sink(formatter), target="pretty")
  logger.info("hello", fields=[field("mode", "pretty")])
}
```

```mbt check
test {
  if native_files_supported() {
    let logger = Logger::new(file_sink("bitlogger.log"), target="file")
    logger.info("hello", fields=[field("kind", "file")])
    ignore(logger.sink.flush())
    ignore(logger.sink.close())
  }
}
```
