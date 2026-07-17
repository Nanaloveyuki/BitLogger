# 异步日志生命周期

当 native 异步应用需要通过异步队列处理日志写入时，使用异步包。库声明的可用目标比可执行 `async fn main` 示例更广，仓库示例仍以 native 为主。

## 导入两个包

```moonbit
import {
  "Nanaloveyuki/BitLogger/src" @log,
  "Nanaloveyuki/BitLogger/src-async" @async_log,
  "moonbitlang/async",
}
```

## 构建、运行、关闭

```moonbit
async fn main {
  let raw = "{\"logger\":{\"min_level\":\"info\",\"target\":\"service.async\",\"sink\":{\"kind\":\"text_console\"}},\"async_config\":{\"max_pending\":64,\"overflow\":\"DropOldest\",\"max_batch\":16,\"linger_ms\":5,\"flush\":\"Batch\"}}"
  let config = @async_log.parse_async_logger_build_config_text(raw) catch {
    err => {
      ignore(err)
      return
    }
  }
  let logger = @async_log.build_async_logger(config)

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    logger.info("worker started", fields=[@log.field("mode", "async")])
    logger.shutdown()
  })
}
```

`run()` 持有 worker 循环。先启动它再记录日志，并调用 `shutdown()`，使待处理记录按配置的 flush 策略结束。

## 运行仓库示例

```bash
moon run examples/async_basic --target native
```

## 下一步

- 查看[队列](../extend/queue.md)中的溢出与 flush 选择。
- 阅读[异步生命周期 API](../api/async.md)；完整契约仍可查询[英文 API 索引](../../api/index.md)。
