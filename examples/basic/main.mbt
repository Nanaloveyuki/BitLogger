fn main {
  let preset_logger = @lib.build_logger(
    @lib.with_queue(
      @lib.text_console(
        min_level=@lib.Level::Info,
        target="preset",
        text_formatter=@lib.TextFormatterConfig::new(show_timestamp=false, separator=" | "),
      ),
      max_pending=2,
      overflow=@lib.QueueOverflowPolicy::DropOldest,
    ),
  )
  preset_logger.info("queued one")
  preset_logger.info("queued two")
  preset_logger.info("queued three")
  ignore(preset_logger.flush())

  @lib.set_default_min_level(@lib.Level::Debug)
  @lib.set_default_target("bitlogger")
  @lib.info("hello from BitLogger", fields=[@lib.field("mode", "demo")])

  // Direct Logger::new(...) composition stays useful for custom sink graphs.
  let logger = @lib.Logger::new(@lib.console_sink(), min_level=@lib.Level::Trace, target="custom")
    .with_context_fields([@lib.field("service", "bitlogger")])
  logger.debug("custom logger ready", fields=[@lib.field("sink", "console")])

  let bound_logger = @lib.Logger::new(
    @lib.console_sink(),
    min_level=@lib.Level::Info,
    target="bound",
  ).bind(@lib.fields([("service", "bitlogger"), ("scope", "audit")]))
  bound_logger.info("bound logger ready", fields=[@lib.field("mode", "demo")])

  let json_logger = @lib.Logger::new(@lib.json_console_sink(), min_level=@lib.Level::Info, target="json")
  json_logger.info("json output", fields=[@lib.field("kind", "example")])

  let fanout_logger = @lib.Logger::new(
    @lib.fanout_sink(@lib.console_sink(), @lib.json_console_sink()),
    min_level=@lib.Level::Info,
    target="fanout",
  )
  fanout_logger.info("dual output", fields=[@lib.field("kind", "fanout")])

  let split_logger = @lib.Logger::new(
    @lib.split_by_level(
      @lib.callback_sink(fn(rec) {
        println("high priority: \{rec.level.label()} \{rec.message}")
      }),
      @lib.console_sink(),
      min_level=@lib.Level::Warn,
    ),
    min_level=@lib.Level::Trace,
    target="split",
  )
  split_logger.info("normal output")
  split_logger.warn("warning output")

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

  let styled_formatter = @lib.text_formatter(
    show_timestamp=false,
    color_mode=@lib.ColorMode::Always,
  ).with_style_tags(
    @lib.default_style_tag_registry()
      .set_tag("accent", fg=Some("#4cc9f0"), bold=true)
      .define_alias("danger", "red"),
  )
  let styled_logger = @lib.Logger::new(
    @lib.text_console_sink(styled_formatter),
    min_level=@lib.Level::Info,
    target="styled",
  )
  styled_logger.info("<accent>styled</> output and <danger>alert</>")

  if @lib.native_files_supported() {
    let file_logger = @lib.Logger::new(
      @lib.file_sink(
        "bitlogger-example.log",
        rotation=Some(@lib.file_rotation(128, max_backups=2)),
      ),
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

  let queue_config = @lib.QueueConfig::new(4, overflow=@lib.QueueOverflowPolicy::DropOldest)
  println(@lib.stringify_queue_config(queue_config))

  let formatter_config = @lib.TextFormatterConfig::new(
    show_timestamp=false,
    separator=" | ",
    field_separator=",",
    template="[{level}] {target} {message} :: {fields}",
  )
  println(@lib.stringify_text_formatter_config(formatter_config))

  let sink_config = @lib.SinkConfig::new(
    kind=@lib.SinkKind::File,
    path="bitlogger-config-demo.log",
    append=false,
    auto_flush=false,
    rotation=Some(@lib.file_rotation(128, max_backups=2)),
    text_formatter=formatter_config,
  )
  println(@lib.stringify_sink_config(sink_config))

  let file_policy = @lib.FileSinkPolicy::new(
    append=false,
    auto_flush=false,
    rotation=Some(@lib.file_rotation(64, max_backups=2)),
  )
  println(@lib.stringify_file_sink_policy(file_policy))

  let file_runtime_logger = @lib.build_logger(
    @lib.LoggerConfig::new(
      sink=@lib.SinkConfig::new(kind=@lib.SinkKind::File, path="bitlogger-runtime-demo.log"),
      queue=Some(@lib.QueueConfig::new(8)),
    ),
  )
  file_runtime_logger.info("runtime file logger ready")
  match file_runtime_logger.file_runtime_state() {
    Some(snapshot) => println(@lib.stringify_runtime_file_state(snapshot, pretty=true))
    None => ()
  }
  ignore(file_runtime_logger.file_close())
}
