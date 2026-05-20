fn main {
  let config = @lib.parse_logger_config_text(
    "{\"min_level\":\"debug\",\"target\":\"demo.config\",\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"separator\":\" | \",\"template\":\"[{level}] {target} {message}\"}},\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"}}",
  ) catch {
    err => {
      ignore(err)
      println("invalid config")
      return
    }
  }

  let logger = @lib.build_logger(config)
  logger.info("queued one")
  logger.info("queued two")
  logger.info("queued three")
  ignore(logger.flush())
}
