# File Output And Rotation

File output is for native applications that need local persistence. Treat it as a native-only capability and keep a console fallback for portable code.

## Check The Capability

```moonbit
if !@log.native_files_supported() {
  println("file logging is unavailable on this target")
  return
}
```

## Build A Rotating File Logger

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

The rotation limit is the size of the active file in bytes. `max_backups=3` retains the rotated backup chain. Always close a file-backed logger during orderly application shutdown.

## Run The Repository Example

```bash
moon run examples/file_rotation --target native
```

## Next Steps

- Add a bounded queue with [Queueing](../extend/queue.md) when bursts should not write synchronously.
- Read [Target boundaries](../extend/targets.md) before sharing the same logging setup with web targets.
- Reference: [`file(...)`](../api/file.md), [`with_file_rotation(...)`](../api/with-file-rotation.md), and [`file_close(...)`](../api/configured-logger-file-close.md).
