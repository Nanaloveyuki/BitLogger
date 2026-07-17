# 高频 API

这一层只覆盖 Examples 和 Extend 中直接使用、或应用启动时高频需要的 API。它按使用主题归纳，避免把阅读路径重新拆回一函数一页。

| 场景 | 中文说明 | 英文精确参考 |
| --- | --- | --- |
| 第一条结构化日志 | [基础记录](./basics.md) | [完整 API 索引](../../api/index.md) |
| 配置、队列与 flush | [配置与队列](./configuration.md) | [config 分类](../../api/index.md) |
| native 文件输出 | [文件输出](./file-output.md) | [file/sink 分类](../../api/index.md) |
| 终端可读性 | [文本格式](./formatting.md) | [formatter 分类](../../api/index.md) |
| 后台异步处理 | [异步生命周期](./async.md) | [async 分类](../../api/index.md) |
| 多目的地与按 level 路由 | [Sink 组合](./composition.md) | [sink 分类](../../api/index.md) |

每个中文页面保留高频签名与行为边界；需要全部参数、错误条件或较少使用的公开符号时，沿页面内链接进入英文原始 API。
