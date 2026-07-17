# 目标平台边界

BitLogger 保持可移植的结构化日志表面，但 native 文件输出与异步 worker 行为依赖目标平台。应把这些边界写在应用代码中，而不是假设每种 Sink 在所有后端都相同。

## 可移植默认值

`console(...)`、`json_console(...)`、结构化 fields、filter、patch 与普通 Logger 表面适合作为跨端共享代码的起点。

## 仅 native 的文件输出

```moonbit
if @log.native_files_supported() {
  let logger = @log.build_logger(@log.file("service.log") catch {
    err => {
      ignore(err)
      return
    }
  })
  logger.info("file output enabled")
}
```

文件 Sink 需要 native 文件系统支持。面向 web 目标的代码不应无条件构造只包含文件输出的配置。

## 异步库与异步入口

异步库在声明目标上提供兼容表面，但可执行 `async fn main` 的入口支持更严格。请把 native-only 可执行示例与可移植库代码分开。

## 英文 API

- [`native_files_supported()`](../../api/native-files-supported.md)
- [目标验证](../../api/target-verification.md)
- [异步日志生命周期](../examples/async.md)
