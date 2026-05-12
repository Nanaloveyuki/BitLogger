# BitLogger

BitLogger is a minimal structured logger for MoonBit.

BitLogger 是一个使用 MoonBit 编写的结构化日志库.

## Features / 特性

- structured logging with levels, targets, and key-value fields
- 支持 level、target 与结构化字段的基础日志能力
- composable sinks, filters, patches, and queue wrappers
- 支持 sink、filter、patch、queue 包装等组合能力
- configurable text formatting with template and style tags
- 支持 template、style tag 与彩色输出的文本格式化能力
- config-driven logger assembly and JSON export / parse helpers
- 支持配置驱动组装以及 JSON 解析 / 导出能力
- native file sink support with rotation and runtime observability
- 支持 native file sink、基础 rotation 与运行时可观测性

## Example / 示例

```mbt check
test {
  let logger = Logger::new(console_sink(), min_level=Level::Debug, target="demo")
    .with_timestamp()
    .with_context_fields([field("service", "bitlogger")])
  logger.info("starting", fields=[field("port", "8080")])
}
```

## Where To Go Next / 下一步

- examples / 示例:
  - `../examples/basic/`
  - `../examples/async_basic/`
- package-level API docs / 单接口 API 文档:
  - `../docs/api/`
- common entry points / 常用入口:
  - `Logger::new(...)`
  - `async_logger(...)`
  - `build_logger(...)`
  - `build_async_logger(...)`

## Notes / 说明

- This README is intentionally minimal and no longer acts as a full API catalog.
- 当前 README 仅保留 package 定位、关键特性与最小示例，不再承担完整 API 手册职责。
- Detailed API docs now live under `docs/api/` one interface per file.
- 详细 API 已迁移到 `docs/api/`，按“一接口一文件”维护。
