# 文本格式与样式

格式化只改变呈现，记录本身的 level、target、message 和 fields 不变。面向人时使用文本输出；由其他系统解析时使用 JSON。

## 自定义文本形状

```moonbit
let logger = @log.build_logger(
  @log.text_console(
    min_level=@log.Level::Info,
    target="service",
    text_formatter=@log.TextFormatterConfig::new(
      show_timestamp=false,
      field_separator=",",
      template="[{level}] {target} {message} :: {fields}",
    ),
  ),
)

logger.info("ready", fields=[@log.field("port", "8080")])
```

模板控制可见顺序。fields 应保持独立于 message，以便不同 Sink 一致渲染。

## 添加命名样式

```moonbit
let formatter = @log.text_formatter(
  show_timestamp=false,
  color_mode=@log.ColorMode::Always,
).with_style_tags(
  @log.default_style_tag_registry()
  .set_tag("accent", fg=Some("#4cc9f0"), bold=true),
)
```

样式标签是终端呈现元数据，不应作为唯一的业务或运维语义；语义仍应保存在 level、target 与 fields 中。

## API

阅读[文本格式 API](../api/formatting.md)；完整契约仍可查询[英文 API 索引](../../api/index.md)。
