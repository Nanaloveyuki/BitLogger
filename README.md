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

README 仅保留项目定位、关键特性和最小使用入口。详细 API 请查看 `docs/api/`。

## 🧭 后端兼容

| 模块 / 能力 | native / llvm | js / wasm / wasm-gc |
| --- | --- | --- |
| `bitlogger` 主包 | 支持 | 支持 |
| `file_sink(...)` | 支持 | 不支持, `native_files_supported()` 返回 `false` |
| `bitlogger_async` | 支持原生 worker 语义 | 支持兼容实现 |
| `examples/async_basic` | 支持 | 受 `async fn main` 入口限制, 当前不提供 |

## ❇️ 关键特性

- 结构化日志基础能力：level、record、formatter、sink、target、context field。
- 组合式设计：支持 filter、patch、fanout、split、callback、queued sink 等组合能力。
- 配置驱动：支持 JSON 配置解析、导出与 `build_logger(...)` / `build_async_logger(...)` 运行时组装。
- 文本格式化：支持 `text_formatter(...)`、template、style tag、`color_mode` / `style_markup`。
- Native 文件输出：支持 file sink、基础 size rotation、reopen、failure counter 与运行时状态读取。
- 异步层：提供独立 `bitlogger_async` package，支持 queue、worker lifecycle、runtime state 和跨端兼容实现。

## 🚀 快速开始

```moonbit
let logger = Logger::new(console_sink(), min_level=Level::Info, target="demo")
  .with_timestamp()
  .with_context_fields([field("service", "bitlogger")])

logger.info("starting", fields=[field("port", "8080")])
```

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

- `bitlogger/`: 主日志库 package。
- `bitlogger_async/`: 基于 `moonbitlang/async` 的异步日志层。
- `docs/api/`: 单接口粒度 API 文档。
- `examples/basic/`: 最小同步示例。
- `examples/async_basic/`: 异步 logger 示例。

## 🔗 文档入口

- [Mooncake 文档页](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [English README](./docs/README-en.md)
- [bitlogger package README](./bitlogger/README.mbt.md)
- `docs/api/` 中的单接口文档，例如:
- [logger-new.md](./docs/api/logger-new.md)
- [async-logger.md](./docs/api/async-logger.md)
- [build-logger.md](./docs/api/build-logger.md)
- [build-async-logger.md](./docs/api/build-async-logger.md)

## 📝 说明

- `README.md` 不再承担 API 手册职责，详细接口、配置字段和运行时控制面已回收到 `docs/api/`。
- 如果你在找具体方法如 `with_filter(...)`、`file_reopen(...)`、`AsyncLogger::shutdown(...)`、`ConfiguredLogger::file_runtime_state()`，请直接查看 `docs/api/`。
- 如果你在找完整可运行用法，优先看 `examples/`。

## 🧵 异步层概览

- `bitlogger_async` 提供 `AsyncLogger`、后台 `run()` worker、有界 async queue 与生命周期诊断接口。
- 多端编译已支持：`native/llvm` 保留原生 worker 语义，`js` / `wasm` / `wasm-gc` 提供兼容实现。
- 当前 `examples/async_basic` 仍保留 `native` target，因为 `moonbitlang/async` 的 `async fn main` 入口限制尚未完全解除。
