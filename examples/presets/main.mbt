fn main {
  let config = @lib.with_queue(
    @lib.text_console(
      min_level=@lib.Level::Info,
      target="demo.preset",
      text_formatter=@lib.TextFormatterConfig::new(
        show_timestamp=false,
        separator=" | ",
      ),
    ),
    max_pending=4,
    overflow=@lib.QueueOverflowPolicy::DropOldest,
  )

  let logger = @lib.build_logger(config)
  logger.info("preset logger ready", fields=[@lib.field("kind", "portable")])
  logger.info("preset logger queued", fields=[@lib.field("step", "two")])
  ignore(logger.flush())

  if @lib.native_files_supported() {
    let file_config = @lib.with_file_rotation(
      @lib.file(
        "preset-example.log",
        min_level=@lib.Level::Info,
        target="demo.preset.file",
        auto_flush=true,
      ),
      256,
      max_backups=2,
    ) catch {
      err => {
        ignore(err)
        println("invalid file preset config")
        return
      }
    }

    let file_logger = @lib.build_logger(file_config)
    file_logger.info("file preset ready", fields=[@lib.field("kind", "native-only")])
    ignore(file_logger.flush())
    ignore(file_logger.file_close())
  } else {
    println("file presets are skipped on this backend because native file support is unavailable")
  }
}
