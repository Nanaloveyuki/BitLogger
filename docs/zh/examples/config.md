# 配置驱动构建

当 level、目标名、输出方式或队列策略应由部署配置决定时，使用这一流程。

## 解析、构建、记录

```moonbit
let raw = "{\"min_level\":\"info\",\"target\":\"service\",\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"separator\":\" | \"}},\"queue\":{\"max_pending\":64,\"overflow\":\"DropOldest\"}}"

let config = @log.parse_logger_config_text(raw) catch {
  err => {
    ignore(err)
    println("invalid logger configuration")
    return
  }
}

let logger = @log.build_logger(config)
logger.info("configured logger ready")
ignore(logger.flush())
```

解析先验证数据，再构造运行时 Logger。真实部署应将原始配置放在应用代码之外，并在配置进入进程的边界处理错误。

## 运行仓库示例

```bash
moon run examples/config_build
```

## 下一步

- 需要明确选择满队列时的行为，阅读[队列](../extend/queue.md)。
- 需要后台 worker 生命周期时，阅读[异步日志生命周期](./async.md)。
- 英文 API：[`parse_logger_config_text(...)`](../../api/parse-logger-config-text.md)、[`build_logger(...)`](../../api/build-logger.md)、[`with_queue(...)`](../../api/with-queue.md)。
