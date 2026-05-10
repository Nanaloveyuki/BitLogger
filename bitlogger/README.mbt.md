# BitLogger

BitLogger is a minimal structured logger for MoonBit.

BitLogger 是一个使用 MoonBit 编写的结构化日志库.

## Features / 特性

- log levels: `Trace`, `Debug`, `Info`, `Warn`, `Error`
- 日志级别: `Trace`, `Debug`, `Info`, `Warn`, `Error`
- structured key-value fields
- 结构化字段: `field("key", "value")`
- sink abstraction
- sink 抽象与组合接口
- default global console logger
- 默认全局 logger 辅助函数
- context fields via `with_context_fields(...)`
- 通过 `with_context_fields(...)` 添加上下文字段
- child target composition via `child(...)`
- 通过 `child(...)` 组合层级 target
- optional timestamps via `with_timestamp()`
- 通过 `with_timestamp()` 启用时间戳
- JSON console output via `json_console_sink()`
- `json_console_sink()` 提供 JSON 控制台输出
- sink composition via `fanout_sink(...)`
- `fanout_sink(...)` 支持多 sink 组合
- sink routing via `split_sink(...)` and `split_by_level(...)`
- `split_sink(...)`, `split_by_level(...)` 支持按谓词或 level 将日志路由到不同 sink
- custom callback sink via `callback_sink(...)`
- `callback_sink(...)` 支持自定义外部集成
- buffered sink via `buffered_sink(...)`
- `buffered_sink(...)` 支持内存缓冲与 flush
- filter sink via `filter_sink(...)`
- `filter_sink(...)` 支持按 `Record` 条件筛选输出
- reusable filter helpers such as `target_has_prefix(...)`, `message_contains(...)`, and `field_equals(...)`
- 提供 `target_has_prefix(...)`, `message_contains(...)`, `field_equals(...)` 等可复用过滤辅助函数
- record patching via `with_patch(...)` and `patch_sink(...)`
- 支持 `with_patch(...)`, `patch_sink(...)` 以及常见 record patch helper
- context binding via `bind(...)` and `fields(...)`
- 支持 `bind(...)`, `fields(...)`, 更方便封装上下文字段
- explicit queued delivery via `queued_sink(...)` and `with_queue(...)`
- 支持 `queued_sink(...)`, `with_queue(...)`, 有界积压与溢出策略
- configurable text formatting via `text_formatter(...)`, `format_text(...)`, `text_console_sink(...)`, and template-driven `template` output
- 支持 `text_formatter(...)`, `format_text(...)`, `text_console_sink(...)` 以及模板化 `template` 文本输出
- lightweight style tags via `color_mode`, inline markup, `TextStyle`, `StyleTagRegistry`, custom tags, and builtin-tag overrides
- 支持 `color_mode`, inline markup, `TextStyle`, `StyleTagRegistry`, 自定义标签与内置标签覆盖
- JSON config parsing via `parse_logger_config_text(...)` and `stringify_logger_config(...)`
- 支持 `parse_logger_config_text(...)`, `stringify_logger_config(...)` 进行最小 JSON 配置读写
- `TextFormatter` / `TextFormatterConfig` now support `color_mode = Never | Auto | Always`
- `TextFormatter` / `TextFormatterConfig` 现支持 `color_mode = Never | Auto | Always`
- `QueueConfig` / `TextFormatterConfig` / `SinkConfig` can also be exported independently through dedicated JSON helpers
- `QueueConfig` / `TextFormatterConfig` / `SinkConfig` 也可分别通过专用 JSON helper 单独导出
- config-driven logger assembly via `build_logger(...)`
- 支持 `build_logger(...)` 将配置组装为可直接使用的 logger
- native-only file output via `file_sink(...)`, with basic size rotation, backup retention, explicit `reopen()` / `reopen_with_current_policy()` / `reopen_append()` / `reopen_truncate()`, and failure counters
- 支持 `file_sink(...)`, 基础 size rotation / backup retention, 显式 `reopen()` / `reopen_with_current_policy()` / `reopen_append()` / `reopen_truncate()` 与失败计数, 仅在 `native/llvm` backend 可用

## Example / 示例

```mbt check
test {
  let logger = Logger::new(console_sink(), min_level=Level::Debug, target="demo")
    .with_timestamp()
  logger.info("starting", fields=[field("port", "8080")])
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="app").child("worker")
  logger.info("ready")
}
```

```mbt check
test {
  let logger = Logger::new(
    fanout_sink(console_sink(), json_console_sink()),
    min_level=Level::Info,
    target="demo",
  )
  logger.info("ready", fields=[field("mode", "fanout")])
}
```

```mbt check
test {
  let logger = Logger::new(
    callback_sink(fn(rec) {
      println("callback saw [\{rec.target}] \{rec.message}")
    }),
    target="hook",
  )
  logger.info("hello")
}
```

```mbt check
test {
  let sink = buffered_sink(console_sink(), flush_limit=2)
  let logger = Logger::new(sink, target="buffered")
  logger.info("one")
  logger.info("two")
  sink.flush()
}
```

```mbt check
test {
  let sink = filter_sink(console_sink(), fn(rec) {
    rec.target == "kept"
  })
  let kept = Logger::new(sink, target="kept")
  let dropped = Logger::new(sink, target="dropped")
  kept.info("visible")
  dropped.info("hidden")
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="service")
    .with_filter(all_of([
      target_has_prefix("service"),
      message_contains("visible"),
    ]))
  logger.info("hidden")
  logger.child("api").info("visible")
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="auth")
    .with_patch(compose_patches([
      prefix_message("[safe] "),
      redact_fields(["token"]),
      append_fields([field("service", "bitlogger")]),
    ]))
  logger.info("login", fields=[field("user", "alice"), field("token", "secret")])
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="audit")
    .bind(fields([("service", "bitlogger"), ("scope", "login")]))
  logger.info("accepted", fields=[field("user", "alice")])
}
```

```mbt check
test {
  let logger = Logger::new(console_sink(), target="queue")
    .with_queue(max_pending=2, overflow=QueueOverflowPolicy::DropOldest)
  logger.info("one")
  logger.info("two")
  logger.info("three")
  ignore(logger.sink.flush())
}
```

```mbt check
test {
  let logger = Logger::new(
    split_by_level(
      callback_sink(fn(rec) {
        println("high priority: \{rec.level.label()} \{rec.message}")
      }),
      console_sink(),
      min_level=Level::Warn,
    ),
    min_level=Level::Trace,
    target="split",
  )
  logger.info("normal output")
  logger.warn("warning output")
}
```

```mbt check
test {
  let formatter = text_formatter(
    show_timestamp=false,
    field_separator=",",
    template="[{level}] {target} {message} :: {fields}",
    color_mode=ColorMode::Always,
  )
  let logger = Logger::new(text_console_sink(formatter), target="pretty")
  logger.info("hello", fields=[field("mode", "pretty")])
}
```

```mbt check
test {
  let formatter = text_formatter(
    show_timestamp=false,
    color_mode=ColorMode::Always,
  ).with_style_tags(
    default_style_tag_registry()
      .set_tag("accent", fg=Some("#4cc9f0"), bold=true)
      .define_alias("danger", "red"),
  )
  let logger = Logger::new(text_console_sink(formatter), target="styled")
  logger.info("<accent>styled</> output and <danger>alert</>")
}
```

```mbt check
test {
  let formatter = text_formatter(
    color_mode=ColorMode::Always,
  ).without_style_markup()
  let logger = Logger::new(text_console_sink(formatter), target="raw")
  logger.info("<red>kept as raw text</>")
}
```

```mbt check
test {
  let config = parse_logger_config_text(
    "{\"min_level\":\"debug\",\"target\":\"config.demo\",\"timestamp\":true,\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"field_separator\":\",\",\"template\":\"[{level}] {target} {message} :: {fields}\",\"color_mode\":\"always\"}},\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"}}",
  )
  let logger = build_logger(config)
  logger.info("configured from json")
  ignore(logger.flush())
}
```

```mbt check
test {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"color_mode\":\"always\",\"style_tags\":{\"accent\":{\"fg\":\"#4cc9f0\",\"bold\":true}}}}}",
  )
  let logger = build_logger(config)
  logger.info("<accent>styled from json</>")
}
```

```mbt check
test {
  let config = parse_logger_config_text(
    "{\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"color_mode\":\"always\",\"style_markup\":\"disabled\"}}}",
  )
  let logger = build_logger(config)
  logger.info("<red>still raw</>")
}
```

## Formatter Template / 模板格式

- supported tokens / 支持的 token: `{timestamp}`, `{timestamp_ms}`, `{level}`, `{target}`, `{message}`, `{fields}`
- `color_mode` / `color_mode`: `never`, `auto`, `always`
- `style_markup` / `style_markup`: `disabled`, `builtin`, `full`
- inline style tags / inline 样式标签: `<red>...</>`, `<b>...</>`, `<#ff0000>...</>`, `<bg:#202020>...</>`
- builtin semantic tags / 内置语义标签: `<accent>`, `<info>`, `<success>`, `<warning>`, `<danger>`, `<muted>`
- runtime style tags / 运行期样式标签: `TextStyle`, `StyleTagRegistry`, `style_tag_registry()`, `default_style_tag_registry()`, `set_tag(...)`, `define_alias(...)`
- style tag priority / 标签优先级: formatter local `style_tags` > global style tag registry > builtin tags
- `sink.text_formatter.style_tags` / `sink.text_formatter.style_tags` 现支持最小对象映射: `fg`, `bg`, `bold`, `dim`, `italic`, `underline`
- `define_alias(...)` is still runtime-only / `define_alias(...)` 目前仍为运行期 API
- disabled or missing parts render as empty text / 被关闭或缺失的部分会渲染为空字符串
- `template` is intentionally a simple token replacement layer, not a full DSL / `template` 使用轻量 token 替换方式, 不是完整 DSL

```mbt check
test {
  if native_files_supported() {
    let logger = Logger::new(
      file_sink("bitlogger.log", rotation=Some(file_rotation(128, max_backups=2))),
      target="file",
    )
    logger.info("hello", fields=[field("kind", "file")])
    ignore(logger.sink.flush())
    ignore(logger.sink.close())
  }
}
```

```mbt check
test {
  let logger = build_logger(
    LoggerConfig::new(
      sink=SinkConfig::new(kind=SinkKind::File, path="bitlogger-runtime.log"),
      queue=Some(QueueConfig::new(16)),
    ),
  )
  logger.info("queued hello")
  match logger.file_runtime_state() {
    Some(snapshot) => println(stringify_runtime_file_state(snapshot, pretty=true))
    None => ()
  }
}
```

## File Rotation / 文件轮转

- basic rotation is size-based / 基础轮转按文件大小触发
- `file_rotation(max_bytes, max_backups=...)` controls threshold and retained backups / `file_rotation(max_bytes, max_backups=...)` 控制触发阈值和保留备份数
- JSON config uses `sink.rotation.max_bytes` and `sink.rotation.max_backups` / JSON 配置使用 `sink.rotation.max_bytes` 与 `sink.rotation.max_backups`
- `FileSink::reopen()` can explicitly reopen the current file handle, `FileSink::reopen_with_current_policy()` makes the stored-policy reopen path explicit, and `FileSink::reopen_append()` / `FileSink::reopen_truncate()` cover the two common reopen modes directly / `FileSink::reopen()` 可显式重开当前文件句柄, `FileSink::reopen_with_current_policy()` 会按当前保存的策略重开文件, `FileSink::reopen_append()` / `FileSink::reopen_truncate()` 提供常见的 append 与 truncate 模式
- `append_mode()` exposes the current append policy, and `reopen(append=...)` updates that policy for later reopen calls / `append_mode()` 可读取当前 append 策略, `reopen(append=...)` 会更新后续 reopen 复用的 append 策略
- `set_append_mode(...)` updates the stored append policy without forcing an immediate reopen / `set_append_mode(...)` 可直接更新保存的 append 策略, 不会强制立即 reopen
- `path()` and `auto_flush_enabled()` expose core file sink policy state / `path()` 与 `auto_flush_enabled()` 可读取 file sink 的基础策略状态
- `rotation_enabled()` and `rotation_config()` expose whether rotation is active and which settings are currently applied / `rotation_enabled()` 与 `rotation_config()` 可读取 rotation 是否启用及当前配置参数
- `state()` exposes a single file-sink snapshot including path, availability, append policy, auto-flush, rotation config, and failure counters / `state()` 可一次性读取包含 path, availability, append, auto_flush, rotation 配置与失败计数的 file sink 快照
- `policy()` and `default_policy()` expose the current runtime policy and the sink's original defaults separately / `policy()` 与 `default_policy()` 可分别读取当前运行期策略与 sink 初始默认策略
- `policy_matches_default()` explicitly tells whether the current runtime policy has drifted from the defaults / `policy_matches_default()` 可显式判断当前运行期策略是否已偏离默认策略
- `set_policy(...)` applies append, auto-flush, and rotation as a bundled runtime update / `set_policy(...)` 可将 append, auto_flush, rotation 作为一组运行期策略一次性写回
- `reset_failure_counters()` clears the open/write/flush/rotation counters after diagnostics or recovery / `reset_failure_counters()` 可在排障或恢复后清空 open/write/flush/rotation 失败计数
- `reset_policy()` restores append, auto-flush, and rotation back to the sink's original defaults / `reset_policy()` 可将 append, auto_flush, rotation 恢复到 sink 初始默认策略
- `file_sink_policy_to_json(...)` / `stringify_file_sink_policy(...)` also export standalone file policy snapshots as JSON / `file_sink_policy_to_json(...)` / `stringify_file_sink_policy(...)` 也可将独立 file policy 快照直接导出为 JSON
- `file_sink_state_to_json(...)` / `stringify_file_sink_state(...)` and `runtime_file_state_to_json(...)` / `stringify_runtime_file_state(...)` export snapshots as JSON / `file_sink_state_to_json(...)` / `stringify_file_sink_state(...)` 与 `runtime_file_state_to_json(...)` / `stringify_runtime_file_state(...)` 可将快照直接导出为 JSON
- `set_auto_flush(...)`, `set_rotation(...)`, and `clear_rotation()` allow runtime tuning of core file sink policies / `set_auto_flush(...)`, `set_rotation(...)`, `clear_rotation()` 可在运行期调整 file sink 的基础策略
- `open_failures()`, `write_failures()`, `flush_failures()`, `rotation_failures()` expose basic sink health counters / `open_failures()`, `write_failures()`, `flush_failures()`, `rotation_failures()` 可用于观察基础 sink 健康状态
- `ConfiguredLogger` also forwards file reopen, flush, close, append-mode, path, auto-flush, rotation-config, state snapshot, append setter, policy setter, and failure-counter helpers for config-built file sinks / `ConfiguredLogger` 也会为配置生成的 file sink 转发 reopen, flush, close, append-mode, path, auto-flush, rotation 配置, state 快照, append setter, 策略 setter 与失败计数访问器
- `ConfiguredLogger::file_runtime_state()` also reports whether a file sink is queue-wrapped and exposes the outer queue pending/drop counters together with the inner file snapshot / `ConfiguredLogger::file_runtime_state()` 还可报告 file sink 是否被 queue 包装, 并将外层 queue 的 pending/drop 计数与内层 file 快照一起返回
- `ConfiguredLogger::file_policy()` and `ConfiguredLogger::file_default_policy()` also expose current runtime policy and initial config policy separately / `ConfiguredLogger::file_policy()` 与 `ConfiguredLogger::file_default_policy()` 也可分别读取当前运行期策略与初始配置策略
- `ConfiguredLogger::file_policy_matches_default()` also tells whether the current runtime file policy has drifted from the default config / `ConfiguredLogger::file_policy_matches_default()` 也可显式判断当前运行期 file 策略是否已偏离默认配置
- `ConfiguredLogger::file_set_policy()` also applies a bundled runtime file policy through the config-built control surface / `ConfiguredLogger::file_set_policy()` 也可通过配置式控制面一次性写回 bundled file 策略
- `ConfiguredLogger::file_reset_failure_counters()` also clears file failure counters through the config-built control surface / `ConfiguredLogger::file_reset_failure_counters()` 也可通过配置式控制面清空 file 失败计数
- `ConfiguredLogger::file_reset_policy()` also restores runtime file policy back to the initial config values / `ConfiguredLogger::file_reset_policy()` 也可将运行期 file 策略恢复到初始配置值
- current scope is observability-first, not a full self-healing sink runtime / 当前以可观测性为主, 不提供完整的自恢复 sink runtime.
