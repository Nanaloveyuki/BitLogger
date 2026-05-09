fn main {
  @lib.set_default_min_level(@lib.Level::Debug)
  @lib.set_default_target("bitlogger")
  @lib.info("hello from BitLogger", fields=[@lib.field("mode", "demo")])

  let logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Trace, target="custom")
    .with_context_fields([@lib.field("service", "bitlogger")])
  logger.debug("custom logger ready", fields=[@lib.field("sink", "console")])

  let json_logger = @lib.Logger::new(@lib.json_console_sink(), min_level=@lib.Level::Info, target="json")
  json_logger.info("json output", fields=[@lib.field("kind", "example")])

  let fanout_logger = @lib.Logger::new(
    @lib.fanout_sink(@lib.console_sink(), @lib.json_console_sink()),
    min_level=@lib.Level::Info,
    target="fanout",
  )
  fanout_logger.info("dual output", fields=[@lib.field("kind", "fanout")])

  let timed_logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Info, target="timed")
    .with_timestamp()
  timed_logger.info("timestamp enabled", fields=[@lib.field("kind", "time")])

  let child_logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Info, target="app")
    .child("worker")
  child_logger.info("child target ready")

  let callback_logger = @lib.Logger::new(
    @lib.callback_sink(fn(rec) {
      println("callback saw [\{rec.target}] \{rec.message}")
    }),
    min_level=@lib.Level::Info,
    target="hook",
  )
  callback_logger.info("callback sink ready")

  let pretty_logger = @lib.Logger::new(
    @lib.text_console_sink(
      @lib.text_formatter(
        show_timestamp=false,
        field_separator=",",
        template="[{level}] {target} {message} :: {fields}",
      ),
    ),
    min_level=@lib.Level::Info,
    target="pretty",
  )
  pretty_logger.info("custom text format", fields=[@lib.field("mode", "pretty")])

  if @lib.native_files_supported() {
    let file_logger = @lib.Logger::new(
      @lib.file_sink("bitlogger-example.log"),
      min_level=@lib.Level::Info,
      target="file",
    )
    file_logger.info("native file sink ready", fields=[@lib.field("kind", "file")])
    ignore(file_logger.sink.flush())
    ignore(file_logger.sink.close())
  }

  let buffered = @lib.buffered_sink(@lib.console_sink(), flush_limit=2)
  let buffered_logger = @lib.Logger::new(buffered, min_level=@lib.Level::Info, target="buffered")
  buffered_logger.info("buffered one")
  buffered_logger.info("buffered two")
  buffered.flush()

  let filtered = @lib.filter_sink(
    @lib.console_sink(),
    fn(rec) {
      rec.target == "kept"
    },
  )
  let kept_logger = @lib.Logger::new(filtered, min_level=@lib.Level::Info, target="kept")
  let dropped_logger = @lib.Logger::new(filtered, min_level=@lib.Level::Info, target="dropped")
  kept_logger.info("filter kept this")
  dropped_logger.info("filter dropped this")

  let filtered_logger = @lib.Logger::new(
    @lib.console_sink(),
    min_level=@lib.Level::Info,
    target="service",
  ).with_filter(@lib.all_of([
    @lib.target_has_prefix("service"),
    @lib.message_contains("kept"),
  ]))
  filtered_logger.info("logger filter dropped this")
  filtered_logger.child("api").info("logger filter kept this")

  let patched_logger = @lib.Logger::new(
    @lib.console_sink(),
    min_level=@lib.Level::Info,
    target="auth",
  ).with_patch(@lib.compose_patches([
    @lib.prefix_message("[safe] "),
    @lib.redact_fields(["token"]),
    @lib.append_fields([@lib.field("service", "bitlogger")]),
  ]))
  patched_logger.info("login", fields=[@lib.field("user", "alice"), @lib.field("token", "secret")])

  let queued_logger = @lib.Logger::new(
    @lib.console_sink(),
    min_level=@lib.Level::Info,
    target="queue",
  ).with_queue(max_pending=2, overflow=@lib.QueueOverflowPolicy::DropOldest)
  queued_logger.info("queued one")
  queued_logger.info("queued two")
  queued_logger.info("queued three")
  ignore(queued_logger.sink.flush())

  let config_logger = @lib.parse_and_build_logger(
    "{\"min_level\":\"debug\",\"target\":\"config.demo\",\"timestamp\":true,\"sink\":{\"kind\":\"text_console\",\"text_formatter\":{\"show_timestamp\":false,\"field_separator\":\",\",\"template\":\"[{level}] {target} {message} :: {fields}\"}},\"queue\":{\"max_pending\":2,\"overflow\":\"DropOldest\"}}",
  ) catch {
    err => {
      ignore(err)
      println("config error")
      return
    }
  }
  config_logger.info("configured from json")
  ignore(config_logger.flush())
}
