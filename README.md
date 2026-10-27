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
moon add Nanaloveyuki/BitLogger@0.9.0
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
- [配置构建](./docs/examples/config.md)
- [异步日志生命周期](./docs/examples/async.md)

## 支持情况

- `BitLogger` 当前在 CI 中检查/验证的目标是 `native`、`wasm`、`js`、`wasm-gc`
- `bitlogger_async` 当前在 CI 中检查和测试 `native`、`wasm`、`js`、`wasm-gc`
- `llvm` 目前按实验性目标处理，当前环境未完成验证
- 文件输出是 native 能力；跨端代码里建议先判断 `native_files_supported()`
- `src-async` 可用，但示例 `examples/async_basic` 目前仍按 native 入口提供

## 主要能力

- 结构化日志：level、target、message、fields
- 多种输出方式：console、json console、text console、file
- 可定制文本格式：模板、style tag、颜色控制
- 配置驱动构建：JSON 与 YAML 都进入 `build_logger(...)`、`build_async_logger(...)`
- 组合能力：queue、filter、patch、fanout、split、callback
- 异步日志：独立 `src-async` package
- Trace context：用 OpenTelemetry 标识规范化 `trace_id`、`span_id`、`trace_flags`、`trace_state`，再绑定为字段

## 文档

- [Examples：完整使用流程](./docs/examples/index.md)
- [Extend：队列、组合、格式化和跨端边界](./docs/extend/index.md)
- [API 索引：按公开符号查询](./docs/api/index.md)
- [src package README](./src/README.mbt.md)

仓库内的 `examples/` 目录与 Examples 文档一一对应；文档解释选择、前提、运行命令和后续扩展，源码保持为可执行参考。

## 开发

本地开发与 CI 由 `.moonbit-toolchain` 固定工具链归档 `0.10.17+d971670cd`，安装对应的编译器、CLI 和 core：`moonc v0.10.17+d971670cd (2026-10-23)`、`moon 0.1.20261023 (3778465 2026-10-23)`。CLI 与编译器版本号不同；归档不可用时安装失败，不回退到 latest。

在仓库根目录安装：

```bash
set -eo pipefail
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s -- "$(cat .moonbit-toolchain)"
export PATH="${MOON_HOME:-$HOME/.moon}/bin:$PATH"
moon version --all
moonc -v
moon update
```

Windows 的 PowerShell 安装使用同一归档：

```powershell
$env:MOONBIT_INSTALL_VERSION = (Get-Content .moonbit-toolchain -Raw).Trim()
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
```

native 构建需要 C 工具链；Windows CI 使用 MSYS2 UCRT64 GCC 和 OpenSSL。异步依赖保持 `moonbitlang/async@0.22.4`，本次不升级第三方依赖。异步 native 测试和示例按现有 CI 在 Linux/macOS 运行。

在安装完成的 Bash 环境中执行主要验证；js 测试需要 Node.js，wasm/wasm-gc 测试使用随工具链安装的 moonrun：

```bash
moon fmt --check
moon info
for target in native wasm wasm-gc js; do
  moon check --target "$target" --deny-warn
  moon test --target "$target" --deny-warn
  moon check src-async --target "$target" --deny-warn
  moon test src-async --target "$target" --deny-warn
done
for example in basic console_basic config_build presets text_formatter style_tags file_rotation async_basic; do
  moon run "examples/$example" --target native
done
```

native 集成测试会写入仓库内的 `logs/`；文件轮转示例会在工作目录生成 `bitlogger-example.log` 及轮转备份，因此这两个目录需要可写。完整 CI 流程见 [ci.yml](.github/workflows/ci.yml)。上述命令用于验证新工具链，不代表已经执行或通过；历史发布验证记录保持原样。

### Unreleased

- 开发和所有 MoonBit CI 安装（包括 Windows）固定到编译器 `0.10.17+d971670cd`，对应 CLI `0.1.20261023`；不变更包版本或依赖版本。
- JSON 时间戳转换改用 `Json(value)`，兼容新工具链且保持 UInt64 的字符串表示不变。
