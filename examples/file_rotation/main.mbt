fn main {
  if !@lib.native_files_supported() {
    println("native file sink is not available on this backend; examples/presets stays portable, while file_rotation remains native-focused")
    return
  }

  let logger = @lib.build_logger(
    @lib.with_file_rotation(
      @lib.file(
        "bitlogger-example.log",
        min_level=@lib.Level::Info,
        target="demo.file",
        auto_flush=true,
      ) catch {
        err => {
          ignore(err)
          println("invalid file preset config")
          return
        }
      },
      128,
      max_backups=2,
    ),
  )
  logger.info("file rotation ready", fields=[@lib.field("kind", "file")])
  ignore(logger.flush())
  ignore(logger.file_close())
}
