# BitLogger

BitLogger 是一个使用 MoonBit 编写的结构化日志库，适合命令行工具、服务和需要统一日志输出的项目。

- [Mooncake 文档页](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [English README](./docs/README-en.md)
- [Wiki](https://bitlogger.naloveyuki.top)

## 介绍

BitLogger 提供统一的日志级别、目标名、结构化字段和可定制格式，既可以直接输出到控制台，也可以在 native 环境写入文件，并提供异步日志版本。

## 快速开始

```moonbit
let logger = build_logger(
  text_console(
    min_level=Level::Info,
    target="demo",
    text_formatter=TextFormatterConfig::new(show_timestamp=false, separator=" | "),
  ),
)

logger.info("starting", fields=[field("port", "8080")])
ignore(logger.flush())
```

推荐从 `console(...)`、`json_console(...)`、`text_console(...)`、`file(...)` 这几个入口开始，再按需配合 `with_queue(...)` 或 `with_file_rotation(...)`。

如果你需要自己组合 sink，比如 `fanout`、`split`、`callback`，再使用 `Logger::new(...)`。

## 支持情况

- `BitLogger` 当前在 CI 中检查/验证的目标是 `native`、`js`、`wasm-gc`
- `bitlogger_async` 当前在 CI 中检查 `native`、`js`、`wasm-gc`，测试覆盖 `native`、`js`、`wasm-gc`
- `wasm` 目标在源码 `moon.pkg` 中保留声明，但当前未纳入 CI 验证口径
- `llvm` 目前按实验性目标处理，当前环境未完成验证
- 文件输出是 native 能力；跨端代码里建议先判断 `native_files_supported()`
- `src-async` 可用，但示例 `examples/async_basic` 目前仍按 native 入口提供

## 主要能力

- 结构化日志：level、target、message、fields
- 多种输出方式：console、json console、text console、file
- 可定制文本格式：模板、style tag、颜色控制
- 配置驱动构建：`build_logger(...)`、`build_async_logger(...)`
- 组合能力：queue、filter、patch、fanout、split、callback
- 异步日志：独立 `src-async` package

## 示例

- `examples/console_basic/`：最小 console / json console 示例
- `examples/text_formatter/`：文本格式与模板示例
- `examples/style_tags/`：style tag 与彩色输出示例
- `examples/config_build/`：配置构建示例
- `examples/presets/`：常用预设组合示例
- `examples/file_rotation/`：文件输出与轮转示例，仅适用于 native
- `examples/async_basic/`：异步日志示例

## 文档

- [API 索引](./docs/api/index.md)
- [src package README](./src/README.mbt.md)

常用入口：`text_console(...)`、`file(...)`、`with_queue(...)`、`build_logger(...)`、`build_async_logger(...)`
