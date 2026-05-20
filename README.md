<html>
    <div style="display: flex; justify-content: center; align-items: center; height: 15vh;">
        <h3 title="https://moonbitlang.github.io/OSC2026/index.html#top">2026 MoonBit 国产基础软件生态开源大赛参赛作品</h3>
    </div>
    <div style="display: flex; justify-content: center; align-items: center; height: 8vh;">
        <a href="https://mooncakes.io/docs/Nanaloveyuki/BitLogger" title="点击前往 Mooncake 页面"><b>Mooncake@Nanaloveyuki/BitLogger</b></a>
    </div>
    <div style="display: flex; justify-content: center; align-items: center; height: 2vh;">
        <b>中文 | <a href="./docs/README-en.md">English</a></b>
    </div>
</html>

## 📖 介绍

BitLogger 是一个使用 MoonBit 编写的结构化日志库，目标是提供可组合、可配置、可跨端编译的日志基础设施。

## 🧭 后端兼容

| 模块 / 能力 | native / llvm | js / wasm / wasm-gc |
| --- | --- | --- |
| `src` 主包 | 支持 | 支持 |
| `file_sink(...)` | 支持 | 不支持, `native_files_supported()` 返回 `false` |
| `src-async` | 支持原生 worker 语义 | 支持兼容实现 |
| `examples/async_basic` | 支持 | 受 `async fn main` 入口限制, 当前不提供 |

## ❇️ 关键特性

- 结构化日志基础能力：level、record、formatter、sink、target、context field。
- 组合式设计：支持 filter、patch、fanout、split、callback、queued sink 等组合能力。
- 配置驱动：支持 JSON 配置解析、导出与 `build_logger(...)` / `build_async_logger(...)` 运行时组装。
- 文本格式化：支持 `text_formatter(...)`、template、style tag、`color_mode` / `style_markup`。
- Native 文件输出：支持 file sink、基础 size rotation、reopen、failure counter 与运行时状态读取。
- 异步层：提供独立 `src-async` package，支持 queue、worker lifecycle、runtime state 和跨端兼容实现。

## 🚀 快速开始

```moonbit
let logger = build_logger(
  with_queue(
    text_console(
      min_level=Level::Info,
      target="demo",
      text_formatter=TextFormatterConfig::new(show_timestamp=false, separator=" | "),
    ),
    max_pending=32,
    overflow=QueueOverflowPolicy::DropOldest,
  ),
)

logger.info("starting", fields=[field("port", "8080")])
ignore(logger.flush())
```

推荐先从 `presets + build_logger(...)` 路径开始：`console(...)` / `json_console(...)` / `text_console(...)` / `file(...)` 负责拼装 `LoggerConfig`，`with_queue(...)` / `with_file_rotation(...)` 负责做小范围组合，然后再交给 `build_logger(...)` 构建运行时 logger。

当你需要 `fanout`、`split`、`callback`、`patch` 这类自定义 sink 图组合时，再优先使用 `Logger::new(...)` 直接进行运行时拼装。

异步入口示例：

```moonbit
let logger = async_logger(console_sink(), target="async.demo")
@async.with_task_group(group => {
  group.spawn_bg(() => logger.run())
  logger.info("started")
  logger.shutdown()
})
```

## 📂 仓库结构

- `src/`: 主日志库 package。
- `src-async/`: 基于 `moonbitlang/async` 的异步日志层。
- `docs/api/`: 单接口粒度 API 文档。
- `examples/basic/`: breadth 示例；文件开头就是推荐的 presets + `build_logger(...)` 同步入口，后续继续覆盖更广能力面。
- `examples/console_basic/`: console 与 json console 最小输出示例。
- `examples/text_formatter/`: text formatter / template 示例。
- `examples/style_tags/`: style tag / colored formatter 示例。
- `examples/file_rotation/`: file sink / rotation 示例。
- `examples/config_build/`: `build_logger(...)` 配置驱动示例。
- `examples/presets/`: presets + `build_logger(...)` 示例。
- `examples/async_basic/`: 异步 logger 示例。

## 🔗 文档入口

- [Mooncake 文档页](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [English README](./docs/README-en.md)
- [src package README](./src/README.mbt.md)
- [API 索引](./docs/api/index.md)
- 推荐起步 API: `text_console(...)` / `file(...)` / `with_queue(...)` / `build_logger(...)`
- facade API: `build_application_logger(...)` / `build_library_logger(...)` / `build_application_async_logger(...)`
