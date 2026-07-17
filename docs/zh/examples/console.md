# 控制台与结构化字段

命令行工具和服务都可以从这一流程开始。一条记录由 level、target、message 与可选 fields 构成。

## 安装与导入

```bash
moon new log-demo
cd log-demo
moon add Nanaloveyuki/BitLogger@0.7.1
```

在应用的 `moon.pkg` 中加入：

```moonbit
import {
  "Nanaloveyuki/BitLogger/src" @log,
}
```

## 构建控制台 Logger

```moonbit
fn main {
  let logger = @log.build_logger(
    @log.console(min_level=@log.Level::Info, target="service.http"),
  )

  logger.info("listening", fields=[
    @log.field("port", "8080"),
    @log.field("environment", "development"),
  ])
  logger.warn("slow request", fields=[@log.field("path", "/health")])
}
```

`min_level` 在记录到达 sink 前过滤日志；`target` 用于识别子系统；fields 用于携带可查询上下文，而不是拼接到 message 中。

## 切换为 JSON

保持日志调用不变，只替换配置：

```moonbit
let logger = @log.build_logger(
  @log.json_console(min_level=@log.Level::Info, target="service.http"),
)
```

当日志采集器按行处理结构化记录时，JSON 输出更合适。

## 下一步

- 需要自定义终端输出时，阅读[文本格式](../extend/formatting.md)。
- 需要由 JSON 配置构建时，阅读[配置构建](./config.md)。
- 阅读[基础记录 API](../api/basics.md)；完整契约仍可查询[英文 API 索引](../../api/index.md)。
