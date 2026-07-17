# 队列与溢出策略

当短时日志突发不应立即写入输出 Sink 时使用队列。队列是显式能力，因为丢弃策略必须由应用决定。

## 加入同步队列

```moonbit
let config = @log.with_queue(
  @log.text_console(target="service"),
  max_pending=128,
  overflow=@log.QueueOverflowPolicy::DropOldest,
)
let logger = @log.build_logger(config)

logger.info("queued record")
ignore(logger.flush())
```

`DropOldest` 在队列已满时保留最新运行信息。若更重视先到的记录，可选择 `DropNewest`。在退出边界调用 `flush()`，让待处理记录策略在应用代码中清晰可见。

## 何时改用异步 Logger

同步队列只是普通运行时 Logger 的一层配置。当 native 异步应用需要 worker 生命周期和批处理时，转到[异步日志生命周期](../examples/async.md)。

## 英文 API

- [`with_queue(...)`](../../api/with-queue.md)
- [`QueueConfig`](../../api/queue-config.md)
- [`QueueOverflowPolicy`](../../api/queue-overflow-policy.md)
- [`flush()`](../../api/configured-logger-flush.md)
