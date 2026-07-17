# Target Boundaries

BitLogger keeps a portable structured logging surface, but native file output and async worker behavior are target-sensitive. Keep those boundaries in application code instead of assuming every sink behaves identically everywhere.

## Portable Default

`console(...)`, `json_console(...)`, structured fields, filters, patches, and the ordinary logger surface are the appropriate starting point for code shared across targets.

## Native-Only File Output

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

File sinks need native filesystem support. Do not construct a file-only configuration unconditionally in code intended for web targets.

## Async Library Versus Async Entry Point

The async library exposes a compatibility surface across declared targets, while an executable `async fn main` still has stricter entry-point support. Keep a native-only executable example separate from portable library code.

## API Reference

- [`native_files_supported()`](../api/native-files-supported.md)
- [Target verification](../api/target-verification.md)
- [Async logger lifecycle](../examples/async.md)
