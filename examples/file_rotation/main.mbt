fn main {
  if !@lib.native_files_supported() {
    println("native file sink is not available on this backend")
    return
  }

  let logger = @lib.Logger::new(
    @lib.file_sink(
      "bitlogger-example.log",
      auto_flush=true,
      rotation=Some(@lib.file_rotation(128, max_backups=2)),
    ),
    min_level=@lib.Level::Info,
    target="demo.file",
  )
  logger.info("file rotation ready", fields=[@lib.field("kind", "file")])
  ignore(logger.sink.flush())
  ignore(logger.sink.close())
}
