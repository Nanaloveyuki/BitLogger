///|
test "config subtype json helpers stringify stable shapes" {
  inspect(
    stringify_queue_config(
      QueueConfig::new(8, overflow=QueueOverflowPolicy::DropOldest),
    ),
    content="{\"max_pending\":8,\"overflow\":\"DropOldest\"}",
  )
  inspect(
    stringify_text_formatter_config(
      TextFormatterConfig::new(
        show_timestamp=false,
        show_level=true,
        show_target=false,
        show_fields=true,
        separator=" | ",
        field_separator=",",
        template="[{level}] {message} :: {fields}",
        color_mode=ColorMode::Always,
        color_support=ColorSupport::Basic,
        style_markup=StyleMarkupMode::Builtin,
        target_style_markup=StyleMarkupMode::Builtin,
        fields_style_markup=StyleMarkupMode::Disabled,
        style_tags={ "accent": text_style(fg=Some("#4cc9f0"), bold=true) },
      ),
    ),
    content="{\"show_timestamp\":false,\"show_level\":true,\"show_target\":false,\"show_fields\":true,\"separator\":\" | \",\"field_separator\":\",\",\"template\":\"[{level}] {message} :: {fields}\",\"color_mode\":\"always\",\"color_support\":\"basic\",\"style_markup\":\"builtin\",\"target_style_markup\":\"builtin\",\"fields_style_markup\":\"disabled\",\"style_tags\":{\"accent\":{\"bold\":true,\"dim\":false,\"italic\":false,\"underline\":false,\"fg\":\"#4cc9f0\"}}}",
  )
  inspect(
    stringify_sink_config(
      SinkConfig::new(
        kind=SinkKind::File,
        path="logs/demo.log",
        append=false,
        auto_flush=false,
        rotation=Some(file_rotation(128, max_backups=2)),
        text_formatter=TextFormatterConfig::new(
          show_timestamp=false,
          color_mode=ColorMode::Auto,
        ),
      ),
    ),
    content="{\"kind\":\"file\",\"path\":\"logs/demo.log\",\"append\":false,\"auto_flush\":false,\"text_formatter\":{\"show_timestamp\":false,\"show_level\":true,\"show_target\":true,\"show_fields\":true,\"separator\":\" \",\"field_separator\":\" \",\"template\":\"\",\"color_mode\":\"auto\",\"color_support\":\"truecolor\",\"style_markup\":\"full\",\"target_style_markup\":\"disabled\",\"fields_style_markup\":\"disabled\"},\"rotation\":{\"max_bytes\":128,\"max_backups\":2}}",
  )
  inspect(
    file_rotation_config_to_json(file_rotation_i64(4294967296L, max_backups=2)).stringify(),
    content="{\"max_bytes\":2147483647,\"max_backups\":2,\"max_bytes_i64\":\"4294967296\"}",
  )
}

///|
test "config json helpers export stable structured shapes" {
  let queue_json = queue_config_to_json(
    QueueConfig::new(8, overflow=QueueOverflowPolicy::DropOldest),
  )
  let queue_obj = queue_json.expect_json_object()
  inspect(
    queue_json.stringify(),
    content="{\"max_pending\":8,\"overflow\":\"DropOldest\"}",
  )
  inspect(
    queue_obj.get("max_pending").unwrap().expect_json_number().to_int(),
    content="8",
  )
  inspect(
    queue_obj.get("overflow").unwrap().expect_json_string(),
    content="DropOldest",
  )

  let formatter_json = text_formatter_config_to_json(
    TextFormatterConfig::new(
      show_timestamp=false,
      show_level=true,
      show_target=false,
      show_fields=true,
      separator=" | ",
      field_separator=",",
      template="[{level}] {message} :: {fields}",
      color_mode=ColorMode::Always,
      color_support=ColorSupport::Basic,
      style_markup=StyleMarkupMode::Builtin,
      target_style_markup=StyleMarkupMode::Builtin,
      fields_style_markup=StyleMarkupMode::Disabled,
      style_tags={ "accent": text_style(fg=Some("#4cc9f0"), bold=true) },
    ),
  )
  let formatter_obj = formatter_json.expect_json_object()
  let style_tags_obj = formatter_obj
    .get("style_tags")
    .unwrap()
    .expect_json_object()
  let accent_obj = style_tags_obj.get("accent").unwrap().expect_json_object()
  inspect(
    formatter_obj.get("show_timestamp").unwrap().expect_json_bool(),
    content="false",
  )
  inspect(
    formatter_obj.get("show_target").unwrap().expect_json_bool(),
    content="false",
  )
  inspect(
    formatter_obj.get("separator").unwrap().expect_json_string(),
    content=" | ",
  )
  inspect(
    formatter_obj.get("field_separator").unwrap().expect_json_string(),
    content=",",
  )
  inspect(
    formatter_obj.get("template").unwrap().expect_json_string(),
    content="[{level}] {message} :: {fields}",
  )
  inspect(
    formatter_obj.get("color_mode").unwrap().expect_json_string(),
    content="always",
  )
  inspect(
    formatter_obj.get("color_support").unwrap().expect_json_string(),
    content="basic",
  )
  inspect(
    formatter_obj.get("style_markup").unwrap().expect_json_string(),
    content="builtin",
  )
  inspect(
    formatter_obj.get("target_style_markup").unwrap().expect_json_string(),
    content="builtin",
  )
  inspect(
    formatter_obj.get("fields_style_markup").unwrap().expect_json_string(),
    content="disabled",
  )
  inspect(accent_obj.get("bold").unwrap().expect_json_bool(), content="true")
  inspect(accent_obj.get("fg").unwrap().expect_json_string(), content="#4cc9f0")

  let sink_json = sink_config_to_json(
    SinkConfig::new(
      kind=SinkKind::File,
      path="logs/demo.log",
      append=false,
      auto_flush=false,
      rotation=Some(file_rotation(128, max_backups=2)),
      text_formatter=TextFormatterConfig::new(
        show_timestamp=false,
        color_mode=ColorMode::Auto,
      ),
    ),
  )
  let sink_obj = sink_json.expect_json_object()
  let sink_formatter_obj = sink_obj
    .get("text_formatter")
    .unwrap()
    .expect_json_object()
  let rotation_obj = sink_obj.get("rotation").unwrap().expect_json_object()
  inspect(sink_obj.get("kind").unwrap().expect_json_string(), content="file")
  inspect(
    sink_obj.get("path").unwrap().expect_json_string(),
    content="logs/demo.log",
  )
  inspect(sink_obj.get("append").unwrap().expect_json_bool(), content="false")
  inspect(
    sink_obj.get("auto_flush").unwrap().expect_json_bool(),
    content="false",
  )
  inspect(
    sink_formatter_obj.get("show_timestamp").unwrap().expect_json_bool(),
    content="false",
  )
  inspect(
    sink_formatter_obj.get("color_mode").unwrap().expect_json_string(),
    content="auto",
  )
  inspect(
    rotation_obj.get("max_bytes").unwrap().expect_json_number().to_int(),
    content="128",
  )
  inspect(
    rotation_obj.get("max_backups").unwrap().expect_json_number().to_int(),
    content="2",
  )
  inspect(rotation_obj.get("max_bytes_i64") is None, content="true")

  let wide_rotation_json = file_rotation_config_to_json(
    file_rotation_i64(4294967296L, max_backups=3),
  )
  let wide_rotation_obj = wide_rotation_json.expect_json_object()
  inspect(
    wide_rotation_obj.get("max_bytes").unwrap().expect_json_number().to_int(),
    content="2147483647",
  )
  inspect(
    wide_rotation_obj.get("max_backups").unwrap().expect_json_number().to_int(),
    content="3",
  )
  inspect(
    wide_rotation_obj.get("max_bytes_i64").unwrap().expect_json_string(),
    content="4294967296",
  )

  let logger_json = logger_config_to_json(
    LoggerConfig::new(
      min_level=Level::Warn,
      target="api",
      timestamp=true,
      sink=SinkConfig::new(kind=SinkKind::TextConsole),
      queue=Some(QueueConfig::new(8, overflow=QueueOverflowPolicy::DropNewest)),
    ),
  )
  let logger_obj = logger_json.expect_json_object()
  let logger_sink_obj = logger_obj.get("sink").unwrap().expect_json_object()
  let logger_queue_obj = logger_obj.get("queue").unwrap().expect_json_object()
  inspect(
    logger_obj.get("min_level").unwrap().expect_json_string(),
    content="WARN",
  )
  inspect(logger_obj.get("target").unwrap().expect_json_string(), content="api")
  inspect(
    logger_obj.get("timestamp").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    logger_sink_obj.get("kind").unwrap().expect_json_string(),
    content="text_console",
  )
  inspect(
    logger_queue_obj.get("max_pending").unwrap().expect_json_number().to_int(),
    content="8",
  )
  inspect(
    logger_queue_obj.get("overflow").unwrap().expect_json_string(),
    content="DropNewest",
  )
}

///|
test "logger config json export materializes parsed omitted defaults" {
  let parsed = parse_logger_config_text("{}")
  let logger_json = logger_config_to_json(parsed)
  let logger_obj = logger_json.expect_json_object()
  let sink_obj = logger_obj.get("sink").unwrap().expect_json_object()
  let formatter_obj = sink_obj
    .get("text_formatter")
    .unwrap()
    .expect_json_object()

  inspect(
    logger_json.stringify(),
    content="{\"min_level\":\"INFO\",\"target\":\"\",\"timestamp\":false,\"sink\":{\"kind\":\"console\",\"path\":\"\",\"append\":true,\"auto_flush\":true,\"text_formatter\":{\"show_timestamp\":true,\"show_level\":true,\"show_target\":true,\"show_fields\":true,\"separator\":\" \",\"field_separator\":\" \",\"template\":\"\",\"color_mode\":\"never\",\"color_support\":\"truecolor\",\"style_markup\":\"full\",\"target_style_markup\":\"disabled\",\"fields_style_markup\":\"disabled\"}}}",
  )
  inspect(
    logger_obj.get("min_level").unwrap().expect_json_string(),
    content="INFO",
  )
  inspect(logger_obj.get("target").unwrap().expect_json_string(), content="")
  inspect(
    logger_obj.get("timestamp").unwrap().expect_json_bool(),
    content="false",
  )
  inspect(logger_obj.get("queue") is None, content="true")
  inspect(sink_obj.get("kind").unwrap().expect_json_string(), content="console")
  inspect(sink_obj.get("path").unwrap().expect_json_string(), content="")
  inspect(sink_obj.get("append").unwrap().expect_json_bool(), content="true")
  inspect(
    sink_obj.get("auto_flush").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_timestamp").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_level").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_target").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_fields").unwrap().expect_json_bool(),
    content="true",
  )
  inspect(
    formatter_obj.get("separator").unwrap().expect_json_string(),
    content=" ",
  )
  inspect(
    formatter_obj.get("field_separator").unwrap().expect_json_string(),
    content=" ",
  )
  inspect(
    formatter_obj.get("template").unwrap().expect_json_string(),
    content="",
  )
  inspect(
    formatter_obj.get("color_mode").unwrap().expect_json_string(),
    content="never",
  )
  inspect(
    formatter_obj.get("color_support").unwrap().expect_json_string(),
    content="truecolor",
  )
  inspect(
    formatter_obj.get("style_markup").unwrap().expect_json_string(),
    content="full",
  )
  inspect(
    formatter_obj.get("target_style_markup").unwrap().expect_json_string(),
    content="disabled",
  )
  inspect(
    formatter_obj.get("fields_style_markup").unwrap().expect_json_string(),
    content="disabled",
  )
  inspect(formatter_obj.get("style_tags") is None, content="true")
}

///|
test "default config helpers expose baseline config shapes" {
  let formatter = default_text_formatter_config()
  inspect(formatter.show_timestamp, content="true")
  inspect(color_mode_label(formatter.color_mode), content="never")
  inspect(color_support_label(formatter.color_support), content="truecolor")
  inspect(style_markup_mode_label(formatter.style_markup), content="full")

  let sink = default_sink_config()
  inspect(
    match sink.kind {
      SinkKind::Console => "Console"
      _ => "other"
    },
    content="Console",
  )
  inspect(sink.path, content="")
  inspect(sink.rotation is None, content="true")

  let logger = default_logger_config()
  inspect(logger.min_level.label(), content="INFO")
  inspect(logger.target, content="")
  inspect(logger.timestamp, content="false")
  inspect(logger.queue is None, content="true")
  inspect(
    match logger.sink.kind {
      SinkKind::Console => "Console"
      _ => "other"
    },
    content="Console",
  )
}

///|
