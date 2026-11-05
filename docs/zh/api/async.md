# 异步生命周期 API

异步 API 从 combined config 构建 Logger，再以单 worker 生命周期处理待写入记录。可执行 `async fn main` 仍应按目标平台边界使用。

## 解析与构建

```moonbit
pub fn parse_async_logger_build_config_text(
  input : String,
) -> AsyncLoggerBuildConfig raise

pub fn build_async_logger(
  config : AsyncLoggerBuildConfig,
) -> AsyncLogger[AsyncRuntimeSink]
```

解析函数同时验证 `logger` 与 `async_config` 两部分；缺少任一部分时使用对应默认配置。`build_async_logger(...)` 返回 `AsyncLogger[AsyncRuntimeSink]`：同步配置先选择并组装底层 `RuntimeSink`（包括可选同步队列），再由 `AsyncRuntimeSink` 包装共享状态，并为文件写入与刷新提供真正的异步文件后端。单独构造异步文件 sink 时，应从 `Nanaloveyuki/BitLogger/src-async` 使用 `file_sink_async(...) -> AsyncFileSink`；根 `Nanaloveyuki/BitLogger/src.file_sink(...) -> FileSink` 仍是同步 API。

```moonbit
let sink = @async_log.file_sink_async("app.log")
let logger = @async_log.async_logger(sink)
```

`AsyncFileSink` 的 `write_async(...)` 与 `flush_async()` 使用异步文件后端；其同步 `write(...)` / `flush()` 仍是同步操作。配置构建的异步文件 logger 使用 deferred handle：首次 `write_async(...)` 才真正异步打开文件，打开失败会增加 `open_failures` 并清除不可用 handle，此时该记录同时计入 `write_failures`。`reopen*` 仍是同步控制操作，它安装 deferred handle，由下一次异步写入完成打开。

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
