# Sink 组合 API

当预设输出不足以表达路由规则时，使用 typed `Logger::new(...)` 和 sink 组合函数。它们接收完整 `Record`，因此仍保留 level、target、message 与 fields。

## `Logger::new(...)`

```moonbit
pub fn Logger::new(
  sink : S,
  min_level~ : Level = Level::Info,
  target~ : String = "",
) -> Logger[S]
```

从任意 `Sink` 实现创建 typed Logger。`min_level` 在任何 sink 写入前生效；`target` 是默认值，之后可由 `with_target(...)`、`child(...)` 或单次 `log(..., target=...)` 覆盖。

## `Logger::log_with(...)`

通过调用方提供的 `(S, Record) -> Result[Unit, E]` writer 写入可失败输出，并原样返回结果。`S` 无需实现 `Sink`。低于最小级别时返回 `Ok(())`，不创建记录、不调用 writer；启用时保留 target 覆盖、fields 和可选时间戳。

此方法直接调用 writer；context、filter、patch、fanout、queue 等包装需要 writer 自行支持。现有 `Sink::write` 和 `Logger::log` 保持不抛错。完整签名与用法见 [`Logger::log_with`](../../api/logger-log-with.md)。

## `fanout_sink(...)`

```moonbit
pub fn fanout_sink(left : A, right : B) -> FanoutSink[A, B]
```

每条记录写入两个目的地，适合控制台加 JSON，或控制台加 callback。右侧获得独立记录副本，两个写入在记录值层面互不影响。

## `split_by_level(...)`

```moonbit
pub fn split_by_level(
  left : A,
  right : B,
  min_level~ : Level = Level::Warn,
) -> SplitSink[A, B]
```

达到阈值的记录进入 `left`，低于阈值的记录进入 `right`。典型用法是把 warning/error 单独输出，而 info/debug 留在普通控制台。

## `callback_sink(...)`

```moonbit
pub fn callback_sink(
  callback : (Record) -> Unit,
) -> CallbackSink
```

将完整结构化 `Record` 交给应用回调。适合测试、自定义桥接与集成；它不自动格式化记录。

## 异步文件 sink

异步文件构造器属于 `Nanaloveyuki/BitLogger/src-async`：使用 `file_sink_async(...)` 创建 `AsyncFileSink`，不要将根 `Nanaloveyuki/BitLogger/src.file_sink(...) -> FileSink` 当作异步文件入口。其 `write_async(...)` 与 `flush_async()` 使用异步文件后端。

## `redact_field(...)` 与 `redact_fields(...)`

命中的字段会先交给 `sujy123456/lunasieve` 扫描。没有检出密钥时，整个字段值替换为 `placeholder`（默认 `"***"`）。检出密钥时只替换密钥片段，字段里的其余文本保留。消息正文不参与扫描。

## 英文原始 API

- [`Logger::new(...)`](../../api/logger-new.md)
- [`fanout_sink(...)`](../../api/fanout-sink.md)
- [`split_by_level(...)`](../../api/split-by-level.md)
- [`callback_sink(...)`](../../api/callback-sink.md)
