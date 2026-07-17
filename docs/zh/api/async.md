# 异步生命周期 API

异步 API 从 combined config 构建 Logger，再以单 worker 生命周期处理待写入记录。可执行 `async fn main` 仍应按目标平台边界使用。

## 解析与构建

```moonbit
pub fn parse_async_logger_build_config_text(
  input : String,
) -> AsyncLoggerBuildConfig raise

pub fn build_async_logger(
  config : AsyncLoggerBuildConfig,
) -> AsyncLogger[RuntimeSink]
```

解析函数同时验证 `logger` 与 `async_config` 两部分；缺少任一部分时使用对应默认配置。构建函数先复用同步 `build_logger(config.logger)` 路径，再包裹异步层，因此保留同步 sink、文件与可选同步队列的运行时语义。

```moonbit
let config = @async_log.parse_async_logger_build_config_text(raw) catch {
  err => { ignore(err); return }
}
let logger = @async_log.build_async_logger(config)
```

## `run()`

```moonbit
pub async fn AsyncLogger::run(self : AsyncLogger[S]) -> Unit
```

启动 drain worker。单个 Logger 只能同时拥有一个 worker；已经运行时再次调用会失败，关闭后的 Logger 也不能重新启动。worker 正常在队列关闭时退出；worker 失败时会记录状态并将错误向上传递。

## `shutdown()`

```moonbit
pub async fn AsyncLogger::shutdown(
  self : AsyncLogger[S],
  clear? : Bool = false,
) -> Unit
```

`clear=false` 先等待 idle 再关闭；`clear=true` 立即关闭并放弃待处理记录。两条路径都会等待活动 worker 退出。没有运行 worker 且仍有待处理记录时，`clear=false` 可能无法推进，因此应用应保证先启动 `run()`。

## 英文原始 API

- [`parse_async_logger_build_config_text(...)`](../../api/parse-async-logger-build-config-text.md)
- [`build_async_logger(...)`](../../api/build-async-logger.md)
- [`run()`](../../api/async-logger-run.md)
- [`shutdown()`](../../api/async-logger-shutdown.md)
