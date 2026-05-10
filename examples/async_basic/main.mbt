async fn main {
  let raw = "{\"logger\":{\"min_level\":\"info\",\"target\":\"async.demo\",\"timestamp\":true,\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"separator\":\" | \"}}},\"async_config\":{\"max_pending\":2,\"overflow\":\"DropOldest\",\"max_batch\":4,\"linger_ms\":5,\"flush\":\"Batch\"}}"
  let config = @lib_async.parse_async_logger_build_config_text(raw) catch {
    err => {
      ignore(err)
      return
    }
  }
  println(@lib_async.stringify_async_logger_build_config(config, pretty=true))

  let logger = @lib_async.build_async_logger(config)
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
    logger.child("worker").info("three", fields=[@lib.field("batch", "yes")])
    logger.with_target("skip.demo").info("three")
    logger.shutdown()
  })
}
