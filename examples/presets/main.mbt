fn main {
  let config = @lib.with_queue(
    @lib.with_file_rotation(
      @lib.file(
        "preset-example.log",
        min_level=@lib.Level::Info,
        target="demo.preset",
        auto_flush=true,
      ),
      256,
      max_backups=2,
    ),
    max_pending=4,
    overflow=@lib.QueueOverflowPolicy::DropOldest,
  ) catch {
    err => {
      ignore(err)
      println("invalid preset config")
      return
    }
  }

  let logger = @lib.build_logger(config)
  logger.info("preset logger ready", fields=[@lib.field("kind", "preset")])
  ignore(logger.flush())
  ignore(logger.file_close())
}
