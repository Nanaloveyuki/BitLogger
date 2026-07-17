# 文本格式 API

文本格式只改变呈现，不改变 `Record` 的结构。需要稳定机器消费时，优先使用 `json_console(...)`。

## `text_console(...)`

```moonbit
pub fn text_console(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig
```

生成 `SinkKind::TextConsole` 配置，并复制 formatter 配置。和其他 preset 一样，它不直接构建 Logger，也默认不带队列。

## `TextFormatterConfig` 与 `text_formatter(...)`

`TextFormatterConfig::new(...)` 用于 config-first 路径，控制 timestamp、level、target、fields、分隔符与 template。`text_formatter(...)` 构建直接传给 `text_console_sink(...)` 的运行时 formatter。

```moonbit
let config = @log.text_console(
  text_formatter=@log.TextFormatterConfig::new(
    show_timestamp=false,
    template="[{level}] {target} {message} :: {fields}",
  ),
)
```

## `ColorMode`

`ColorMode` 控制文本 formatter 的颜色策略。终端样式只服务可读性；业务语义仍应放在 level、target 和 fields 中。

## 英文原始 API

- [`text_console(...)`](../../api/text-console.md)
- [`TextFormatterConfig`](../../api/text-formatter-config.md)
- [`text_formatter(...)`](../../api/text-formatter.md)
- [`ColorMode`](../../api/color-mode.md)
