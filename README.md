# BitLogger

BitLogger 是一个使用 MoonBit 编写的结构化日志库，适合命令行工具、服务和需要统一日志输出的项目。

- [Mooncake 文档页](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [English README](./docs/README-en.md)
- [Wiki](https://bitlogger.naloveyuki.top)

## 从第一个日志到扩展能力

BitLogger 的文档按使用路径组织：先完成一个可运行的日志输出，再按需进入文件、配置、异步和组合能力。API 文档保留为精确参考，不需要从 API 文件名开始阅读。

### 1. 安装

从一个空项目开始：

```bash
moon new log-demo
cd log-demo
moon add Nanaloveyuki/BitLogger@0.7.0
```

### 2. 写入第一条结构化日志

在应用 package 的 `moon.pkg` 中导入库：

```moonbit
import {
  "Nanaloveyuki/BitLogger/src" @log,
}
```

然后在 `main.mbt` 中创建控制台 logger：

```moonbit
fn main {
  let logger = @log.build_logger(
    @log.console(min_level=@log.Level::Info, target="app"),
  )

  logger.info("server started", fields=[
    @log.field("port", "8080"),
    @log.field("environment", "development"),
  ])
}
```

运行 `moon run` 后，记录会携带 level、target、message 和 fields。下一步按实际需求选择：

- [控制台与结构化字段](./docs/examples/console.md)
- [文件输出与轮转](./docs/examples/file-rotation.md)
- [JSON 配置构建](./docs/examples/config.md)
- [异步日志生命周期](./docs/examples/async.md)

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

## 文档

- [Examples：完整使用流程](./docs/examples/index.md)
- [Extend：队列、组合、格式化和跨端边界](./docs/extend/index.md)
- [API 索引：按公开符号查询](./docs/api/index.md)
- [src package README](./src/README.mbt.md)

仓库内的 `examples/` 目录与 Examples 文档一一对应；文档解释选择、前提、运行命令和后续扩展，源码保持为可执行参考。
