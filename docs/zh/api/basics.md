# 基础记录 API

控制台示例依赖以下四个入口：先用 preset 描述输出，再由 `build_logger(...)` 构建运行时 Logger，最后用 `field(...)` 附加结构化上下文。

## `console(...)` 与 `json_console(...)`

```moonbit
pub fn console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
) -> LoggerConfig

pub fn json_console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
) -> LoggerConfig
```

两者都只生成 `LoggerConfig`，不会直接创建运行时 Logger。`console(...)` 适合人读输出，`json_console(...)` 适合按行采集的机器读取输出；默认都不带队列。

## `field(...)`

```moonbit
pub fn field(key : String, value : String) -> Field
```

创建一个结构化字段。它保留原始 key/value，不做去重、归一化或校验；应使用稳定字段名，便于下游筛选。

```moonbit
logger.info("accepted", fields=[@log.field("user", "alice")])
```

## `build_logger(...)`

```moonbit
pub fn build_logger(config : LoggerConfig) -> ConfiguredLogger
```

这是同步 config 到运行时的桥梁：它先按 `config.sink` 构建 `RuntimeSink`，再应用可选的 `config.queue`。返回值仍保留普通日志方法，以及适用时的队列和文件控制方法。

```moonbit
let logger = @log.build_logger(
  @log.console(min_level=@log.Level::Info, target="service"),
)
logger.info("ready", fields=[@log.field("port", "8080")])
```

## 英文原始 API

- [`console(...)`](../../api/console.md)
- [`json_console(...)`](../../api/json-console.md)
- [`field(...)`](../../api/field.md)
- [`build_logger(...)`](../../api/build-logger.md)
