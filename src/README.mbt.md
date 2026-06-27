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

```moonbit nocheck
///|
test {
  let logger = build_logger(
    text_console(
      min_level=Level::Debug,
      target="demo",
      text_formatter=TextFormatterConfig::new(
        show_timestamp=false,
        separator=" | ",
      ),
    ),
  )
  logger.info("starting", fields=[field("port", "8080")])
  ignore(logger.flush())
}
```

Recommended sync path / 推荐同步起步路径:

- start with `console(...)`, `json_console(...)`, `text_console(...)`, or `file(...)`
- 先用这些 presets 组装 `LoggerConfig`
- then apply small config helpers such as `with_queue(...)` or `with_file_rotation(...)`
- 再按需叠加 `with_queue(...)` / `with_file_rotation(...)`
- finally call `build_logger(...)` to get the runtime logger
- 最后交给 `build_logger(...)` 构建运行时 logger

Use `Logger::new(...)` instead when you need direct sink composition such as `fanout_sink(...)`, `split_by_level(...)`, `callback_sink(...)`, or custom patch/filter graphs.

如果你需要 `fanout_sink(...)`、`split_by_level(...)`、`callback_sink(...)` 或更自由的 patch/filter 组合，再改用 `Logger::new(...)` 直接拼装运行时 sink 图。

Portable-first note / 跨端优先说明:

- prefer `console(...)`, `json_console(...)`, `text_console(...)`, parsed config, and `build_logger(...)` for cross-target examples
- 跨端示例优先使用这些 console / config 路径
- file sink and `file(...)` remain native-sensitive; gate them with `native_files_supported()` when portability matters
- `file(...)` / file sink 仍然是 native 敏感能力，跨端代码里应先做 `native_files_supported()` 判断
- verified README targets currently center on `native`, `js`, `wasm`, and `wasm-gc`; treat `llvm` as experimental until it is locally re-verified with the required toolchain
- 当前 README 的已验证目标以 `native`、`js`、`wasm`、`wasm-gc` 为准；`llvm` 在完成本地 toolchain 复核前应按实验性目标理解

Project command note / 项目命令说明:

- use `moon check` / `moon test` for local project verification
- 本地项目校验请使用 `moon check` / `moon test`
- `.mbt.md` literate docs still use MoonBit's document-test conventions internally
- `.mbt.md` 文档内部仍沿用 MoonBit 的文档测试约定

## Where To Go Next / 下一步

- examples / 示例:
  - `../examples/basic/`
  - `../examples/console_basic/`
  - `../examples/text_formatter/`
  - `../examples/style_tags/`
  - `../examples/file_rotation/`
  - `../examples/config_build/`
  - `../examples/presets/`
  - `../examples/async_basic/`
  - `console_basic` / `text_formatter` / `style_tags` / `config_build` / `presets` are the portable-first set
  - `console_basic` / `text_formatter` / `style_tags` / `config_build` / `presets` 是 portable-first 示例集
  - `file_rotation` is native-sensitive, and `async_basic` stays native-only because of the current `async fn main` entry limitation
  - `async_basic` currently relies on `moonbitlang/async`, whose upstream README only claims native/LLVM support on Linux/MacOS; do not treat Windows native as a supported baseline for this example until upstream support is stated clearly
  - `file_rotation` 是 native-sensitive，`async_basic` 的 native-only 限制来自当前 `async fn main` 入口能力
  - `async_basic` 当前依赖 `moonbitlang/async`，其上游 README 目前只明确承诺 Linux/MacOS 的 native/LLVM 支持；在上游明确支持之前，不要把 Windows native 当作这个示例的支持基线
- package-level API docs / 单接口 API 文档:
  - `../docs/api/`
- common entry points / 常用入口:
  - `text_console(...)` + `build_logger(...)`
  - `file(...)` + `with_file_rotation(...)` + `build_logger(...)`
  - `Logger::new(...)`
  - `build_logger(...)`
  - `build_application_logger(...)`
  - `build_library_logger(...)`
  - `async_logger(...)`
  - `build_async_logger(...)`

## Notes / 说明

- This README is intentionally minimal and no longer acts as a full API catalog.
- 当前 README 仅保留 package 定位、关键特性与最小示例，不再承担完整 API 手册职责。
- Detailed API docs now live under `docs/api/` one interface per file.
- 详细 API 已迁移到 `docs/api/`，按“一接口一文件”维护。
