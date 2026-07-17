# 示例

示例是 BitLogger 的主学习路径。每页从一个应用需求开始，给出完整最小代码，再链接到英文 API 参考查看精确契约。

## 选择流程

| 需求 | 从这里开始 | 后续扩展 |
| --- | --- | --- |
| 在终端输出结构化日志 | [控制台与字段](./console.md) | [文本格式](../extend/formatting.md) |
| 保存本地日志并限制磁盘占用 | [文件轮转](./file-rotation.md) | [目标平台边界](../extend/targets.md) |
| 由应用配置决定日志行为 | [配置构建](./config.md) | [队列](../extend/queue.md) |
| 在 native 异步应用中处理日志写入 | [异步生命周期](./async.md) | [Sink 组合](../extend/composition.md) |

## 可运行源码

仓库中的 `examples/` 是可执行参考；本目录说明何时选择它们、如何运行，以及下一步应该扩展什么：

- `examples/console_basic`
- `examples/config_build`
- `examples/file_rotation`
- `examples/async_basic`
- `examples/presets`、`examples/text_formatter`、`examples/style_tags`

遇到函数签名、错误语义或边界条件时，请查询[英文 API 参考](../../api/index.md)。
