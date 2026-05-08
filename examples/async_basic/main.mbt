async fn main {
  let logger = @lib_async.async_logger(
    @lib.text_console_sink(@lib.text_formatter(show_timestamp=false, separator=" | ")),
    config=@lib_async.AsyncLoggerConfig::new(
      max_pending=2,
      overflow=@lib_async.AsyncOverflowPolicy::DropOldest,
    ),
    min_level=@lib.Level::Info,
    target="async.demo",
  )
    .with_timestamp()
    .with_context_fields([@lib.field("service", "bitlogger")])
    .with_filter(@lib.target_has_prefix("async"))
    .with_patch(@lib.compose_patches([
      @lib.prefix_message("[async] "),
      @lib.redact_fields(["token"]),
    ]))

  @async.with_task_group(group => {
    group.spawn_bg(allow_failure=true, () => logger.run())
    logger.info("one", fields=[@lib.field("token", "secret")])
    logger.child("worker").info("two")
    logger.with_target("skip.demo").info("three")
    logger.wait_idle()
    logger.close()
  })
}
