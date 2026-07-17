# 文件输出与轮转

文件输出面向需要本地持久化的 native 应用。跨端代码应先判断能力，并保留控制台回退方案。

## 检查能力

```moonbit
if !@log.native_files_supported() {
  println("file logging is unavailable on this target")
  return
}
```

## 构建可轮转文件 Logger

```moonbit
let config = @log.with_file_rotation(
  @log.file(
    "service.log",
    min_level=@log.Level::Info,
    target="service.file",
    auto_flush=true,
  ) catch {
    err => {
      ignore(err)
      return
    }
  },
  1024 * 1024,
  max_backups=3,
)

let logger = @log.build_logger(config)
logger.info("file logger ready")
ignore(logger.flush())
ignore(logger.file_close())
```

轮转阈值是活动文件的字节数，`max_backups=3` 保留备份链。应用有序退出时必须关闭文件 Logger。

## 运行仓库示例

```bash
moon run examples/file_rotation --target native
```

## 下一步

- 写入突发较多时，加入[队列](../extend/queue.md)。
- 与 web 目标共享代码前，阅读[目标平台边界](../extend/targets.md)。
- 英文 API：[`file(...)`](../../api/file.md)、[`with_file_rotation(...)`](../../api/with-file-rotation.md)、[`file_close(...)`](../../api/configured-logger-file-close.md)。
