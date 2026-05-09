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

BitLogger 是一个基于 MoonBit 编写的结构化日志库。

## ❇️ 特点

- 🧩 核心能力清晰：先把 logging core 做稳，再继续扩展 rotation/async 等能力。
- 🏗️ 结构明确：按 `level / record / formatter / sinks / logger / global` 拆文件，便于继续维护。
- 🔌 可扩展：支持 `fanout_sink(...)` 和 `callback_sink(...)`，方便后续桥接文件、指标或外部系统。
- 🧱 可组合：支持 `buffered_sink(...)` 和 `filter_sink(...)`，可以在不引入复杂 runtime 的前提下组合输出策略。
- 🔎 可复用过滤：提供 `target_has_prefix(...)`、`message_contains(...)`、`level_at_least(...)`、`field_equals(...)` 等过滤辅助函数。
- 🩹 可变换 Record：支持 `with_patch(...)`、`patch_sink(...)` 与脱敏/补字段/message 变换 helper。
- 📮 显式队列：支持 `queued_sink(...)` / `with_queue(...)`、有界积压与溢出策略，作为后续 async sink 的 runtime-safe 基础。
- 🧾 可配置文本格式：支持 `text_formatter(...)`、`format_text(...)`、`text_console_sink(...)`、`formatted_callback_sink(...)` 与模板化 `template` 输出。
- 💾 Native 文件输出：支持 `file_sink(...)`，但当前仅保证 `native/llvm` backend 可用。
- 📦 面向 MoonBit：API 和工程结构围绕 MoonBit 的 package / visibility / toolchain 现实约束设计。

## 🚀 快速开始

```moonbit
let logger = Logger::new(console_sink(), min_level=Level::Info, target="demo")
  .with_timestamp()
  .with_context_fields([field("service", "bitlogger")])

logger.info("starting", fields=[field("port", "8080")])
```

<details><summary>层级 target 示例</summary>

```moonbit
let worker = Logger::new(console_sink(), target="app").child("worker")
worker.info("job ready")
```
</details>

<details><summary>自定义 callback sink 示例</summary>

```moonbit
let hook = Logger::new(
  callback_sink(fn(rec) {
    println("callback saw [\{rec.target}] \{rec.message}")
  }),
  target="hook",
)

hook.info("hello")
```
</details>

<details><summary>基础 buffered sink 示例</summary>

```moonbit
let sink = buffered_sink(console_sink(), flush_limit=2)
let logger = Logger::new(sink, target="buffered")

logger.info("one")
logger.info("two")
sink.flush()
```
</details>

<details><summary>基础 filter sink 示例</summary>

```moonbit
let sink = filter_sink(console_sink(), fn(rec) {
  rec.target == "kept"
})

let kept = Logger::new(sink, target="kept")
let dropped = Logger::new(sink, target="dropped")

kept.info("visible")
dropped.info("hidden")
```
</details>

<details><summary>Logger 链式 filter 示例</summary>

```moonbit
let logger = Logger::new(console_sink(), target="service")
  .with_filter(all_of([
    target_has_prefix("service"),
    message_contains("visible"),
  ]))

logger.info("hidden")
logger.child("api").info("visible")
```
</details>

<details><summary>Record patch 示例</summary>

```moonbit
let logger = Logger::new(console_sink(), target="auth")
  .with_patch(compose_patches([
    prefix_message("[safe] "),
    redact_fields(["token"]),
    append_fields([field("service", "bitlogger")]),
  ]))

logger.info("login", fields=[field("user", "alice"), field("token", "secret")])
```
</details>

<details><summary>显式 queue sink 示例</summary>

```moonbit
let logger = Logger::new(console_sink(), target="queue")
  .with_queue(max_pending=2, overflow=QueueOverflowPolicy::DropOldest)

logger.info("one")
logger.info("two")
logger.info("three")
ignore(logger.sink.flush())
```
</details>

<details><summary>自定义文本 formatter 示例</summary>

```moonbit
let formatter = text_formatter(
  show_timestamp=false,
  field_separator=",",
  template="[{level}] {target} {message} :: {fields}",
)
let logger = Logger::new(text_console_sink(formatter), target="pretty")

logger.info("hello", fields=[field("mode", "pretty")])
```

</details>

<details><summary>JSON 配置加载示例</summary>

```moonbit
let config = parse_logger_config_text(
  "{\"min_level\":\"debug\",\"target\":\"config.demo\",\"timestamp\":true,\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"field_separator\":\",\",\"template\":\"[{level}] {target} {message} :: {fields}\"}},\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"}}",
)

let logger = build_logger(config)

logger.info("configured from json")
ignore(logger.flush())
```

</details>

<details><summary>native 文件 sink 示例</summary>

```moonbit
if native_files_supported() {
  let logger = Logger::new(file_sink("bitlogger.log"), target="file")
  logger.info("hello", fields=[field("kind", "file")])
  ignore(logger.sink.flush())
  ignore(logger.sink.close())
}
```
</details>

## 📂 仓库结构

- `bitlogger/`：MoonBit 库 package，本体实现、测试与 Mooncake README
- `examples/basic/`：最小可运行示例

## 🔗 相关文档

- [Mooncake 文档页](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [English README](./docs/README-en.md)

## 📝 配置说明

- 当前提供 JSON 配置层：`parse_logger_config_text(...)`、`stringify_logger_config(...)`、`build_logger(...)`
- 已支持字段：`min_level`、`target`、`timestamp`、`sink.kind`、`sink.path`、`sink.append`、`sink.auto_flush`、`sink.text_formatter`、`queue`
- `sink.text_formatter.template` 当前支持固定 token：`{timestamp}`、`{timestamp_ms}`、`{level}`、`{target}`、`{message}`、`{fields}`
- 当前可由配置直接组装的 sink 类型：`console`、`json_console`、`text_console`、`file`
- `queue` 会作为显式包装层附着在最终 sink 外侧；这仍然是同步 drain 模型，不是 async runtime

## 🧵 异步层

- 当前已新增独立 package：`bitlogger_async/`
- 异步层基于 `moonbitlang/async`，提供 `AsyncLogger`、`async_logger(...)`、后台 `run()` worker 与有界 async queue
- 当前 async API 已支持 `with_context_fields(...)`、`with_filter(...)`、`with_patch(...)`、`with_target(...)`、`child(...)`
- 当前建议用 `shutdown()` 收口 worker；它会在默认模式下先等待队列清空，再关闭 queue 并等待 worker 退出
- 当前已支持基础生命周期观测：`is_closed()`、`is_running()`、`has_failed()`、`last_error()`
- 当前 async worker 已支持 `max_batch` 批量消费，以及 `flush=Never|Batch|Shutdown` 的基础 flush 策略
- 推荐启动方式见 [examples/async_basic/main.mbt](/E:/repo/MooLiteyukiBot/examples/async_basic/main.mbt:1)
- 这层目前仅面向 `native/llvm` backend；它是独立 adapter，不会污染现有同步 core

### Async Config

- 当前已支持 `parse_async_logger_config_text(...)`、`stringify_async_logger_config(...)`、`parse_async_logger_build_config_text(...)` 与 `build_async_logger(...)`
- JSON 顶层结构分为两个字段：`logger` 与 `async_config`
- `logger` 完全复用同步 `LoggerConfig` 的 schema；`async_config` 当前支持 `max_pending`、`overflow`、`max_batch` 与 `flush`
- 当前推荐写法可直接参考 [examples/async_basic/main.mbt](/E:/repo/MooLiteyukiBot/examples/async_basic/main.mbt:1)
