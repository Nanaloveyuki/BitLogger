# 配置与队列 API

这一组 API 将外部 JSON 或 typed config 变成同步 Logger，并明确规定满队列和关闭时的处理方式。

## `parse_logger_config_text(...)`

```moonbit
pub fn parse_logger_config_text(input : String) -> LoggerConfig raise ConfigError
```

解析并验证 JSON，但不构建运行时 Logger。缺省字段使用构造器默认值；无效 JSON、错误类型、未知枚举值或空文件路径都会抛出 `ConfigError`。

```moonbit
let config = @log.parse_logger_config_text(raw) catch {
  err => { ignore(err); return }
}
let logger = @log.build_logger(config)
```

## `with_queue(...)`、`QueueConfig` 与溢出策略

```moonbit
pub fn with_queue(
  config : LoggerConfig,
  max_pending~ : Int = 0,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> LoggerConfig

pub fn QueueConfig::new(
  max_pending : Int,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueueConfig
```

`with_queue(...)` 是 preset 组合入口；`QueueConfig::new(...)` 用于手写 `LoggerConfig`。两者配置同步 `QueuedSink`，不是异步包的 worker 队列。

`DropNewest` 丢弃新到记录，`DropOldest` 丢弃最早待处理记录。选择取决于业务更需要保留早期还是最新状态。

## `flush()`

```moonbit
pub fn ConfiguredLogger::flush(self : ConfiguredLogger) -> Bool
```

在退出或需要确认输出边界时调用。对于队列和文件 sink，它会走对应运行时 flush 路径；返回值表示该路径是否成功。

## 英文原始 API

- [`parse_logger_config_text(...)`](../../api/parse-logger-config-text.md)
- [`with_queue(...)`](../../api/with-queue.md)
- [`QueueConfig`](../../api/queue-config.md)
- [`QueueOverflowPolicy`](../../api/queue-overflow-policy.md)
- [`flush()`](../../api/configured-logger-flush.md)
