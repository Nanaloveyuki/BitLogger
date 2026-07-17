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
    @json_parser.stringify(
      file_rotation_config_to_json(
        file_rotation_i64(4294967296L, max_backups=2),
      ),
    ),
    content="{\"max_bytes\":2147483647,\"max_backups\":2,\"max_bytes_i64\":\"4294967296\"}",
  )
}

///|
test "config json helpers export stable structured shapes" {
  let queue_json = queue_config_to_json(
    QueueConfig::new(8, overflow=QueueOverflowPolicy::DropOldest),
  )
  let queue_obj = queue_json.as_object().unwrap()
  inspect(
    @json_parser.stringify(queue_json),
    content="{\"max_pending\":8,\"overflow\":\"DropOldest\"}",
  )
  inspect(
    queue_obj.get("max_pending").unwrap().as_number().unwrap().to_int(),
    content="8",
  )
  inspect(
    queue_obj.get("overflow").unwrap().as_string().unwrap(),
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
  let formatter_obj = formatter_json.as_object().unwrap()
  let style_tags_obj = formatter_obj
    .get("style_tags")
    .unwrap()
    .as_object()
    .unwrap()
  let accent_obj = style_tags_obj.get("accent").unwrap().as_object().unwrap()
  inspect(
    formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(),
    content="false",
  )
  inspect(
    formatter_obj.get("show_target").unwrap().as_bool().unwrap(),
    content="false",
  )
  inspect(
    formatter_obj.get("separator").unwrap().as_string().unwrap(),
    content=" | ",
  )
  inspect(
    formatter_obj.get("field_separator").unwrap().as_string().unwrap(),
    content=",",
  )
  inspect(
    formatter_obj.get("template").unwrap().as_string().unwrap(),
    content="[{level}] {message} :: {fields}",
  )
  inspect(
    formatter_obj.get("color_mode").unwrap().as_string().unwrap(),
    content="always",
  )
  inspect(
    formatter_obj.get("color_support").unwrap().as_string().unwrap(),
    content="basic",
  )
  inspect(
    formatter_obj.get("style_markup").unwrap().as_string().unwrap(),
    content="builtin",
  )
  inspect(
    formatter_obj.get("target_style_markup").unwrap().as_string().unwrap(),
    content="builtin",
  )
  inspect(
    formatter_obj.get("fields_style_markup").unwrap().as_string().unwrap(),
    content="disabled",
  )
  inspect(accent_obj.get("bold").unwrap().as_bool().unwrap(), content="true")
  inspect(accent_obj.get("fg").unwrap().as_string().unwrap(), content="#4cc9f0")

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
  let sink_obj = sink_json.as_object().unwrap()
  let sink_formatter_obj = sink_obj
    .get("text_formatter")
    .unwrap()
    .as_object()
    .unwrap()
  let rotation_obj = sink_obj.get("rotation").unwrap().as_object().unwrap()
  inspect(sink_obj.get("kind").unwrap().as_string().unwrap(), content="file")
  inspect(
    sink_obj.get("path").unwrap().as_string().unwrap(),
    content="logs/demo.log",
  )
  inspect(sink_obj.get("append").unwrap().as_bool().unwrap(), content="false")
  inspect(
    sink_obj.get("auto_flush").unwrap().as_bool().unwrap(),
    content="false",
  )
  inspect(
    sink_formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(),
    content="false",
  )
  inspect(
    sink_formatter_obj.get("color_mode").unwrap().as_string().unwrap(),
    content="auto",
  )
  inspect(
    rotation_obj.get("max_bytes").unwrap().as_number().unwrap().to_int(),
    content="128",
  )
  inspect(
    rotation_obj.get("max_backups").unwrap().as_number().unwrap().to_int(),
    content="2",
  )
  inspect(rotation_obj.get("max_bytes_i64") is None, content="true")

  let wide_rotation_json = file_rotation_config_to_json(
    file_rotation_i64(4294967296L, max_backups=3),
  )
  let wide_rotation_obj = wide_rotation_json.as_object().unwrap()
  inspect(
    wide_rotation_obj.get("max_bytes").unwrap().as_number().unwrap().to_int(),
    content="2147483647",
  )
  inspect(
    wide_rotation_obj.get("max_backups").unwrap().as_number().unwrap().to_int(),
    content="3",
  )
  inspect(
    wide_rotation_obj.get("max_bytes_i64").unwrap().as_string().unwrap(),
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
  let logger_obj = logger_json.as_object().unwrap()
  let logger_sink_obj = logger_obj.get("sink").unwrap().as_object().unwrap()
  let logger_queue_obj = logger_obj.get("queue").unwrap().as_object().unwrap()
  inspect(
    logger_obj.get("min_level").unwrap().as_string().unwrap(),
    content="WARN",
  )
  inspect(logger_obj.get("target").unwrap().as_string().unwrap(), content="api")
  inspect(
    logger_obj.get("timestamp").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    logger_sink_obj.get("kind").unwrap().as_string().unwrap(),
    content="text_console",
  )
  inspect(
    logger_queue_obj.get("max_pending").unwrap().as_number().unwrap().to_int(),
    content="8",
  )
  inspect(
    logger_queue_obj.get("overflow").unwrap().as_string().unwrap(),
    content="DropNewest",
  )
}

///|
test "logger config json export materializes parsed omitted defaults" {
  let parsed = parse_logger_config_text("{}")
  let logger_json = logger_config_to_json(parsed)
  let logger_obj = logger_json.as_object().unwrap()
  let sink_obj = logger_obj.get("sink").unwrap().as_object().unwrap()
  let formatter_obj = sink_obj
    .get("text_formatter")
    .unwrap()
    .as_object()
    .unwrap()

  inspect(
    @json_parser.stringify(logger_json),
    content="{\"min_level\":\"INFO\",\"target\":\"\",\"timestamp\":false,\"sink\":{\"kind\":\"console\",\"path\":\"\",\"append\":true,\"auto_flush\":true,\"text_formatter\":{\"show_timestamp\":true,\"show_level\":true,\"show_target\":true,\"show_fields\":true,\"separator\":\" \",\"field_separator\":\" \",\"template\":\"\",\"color_mode\":\"never\",\"color_support\":\"truecolor\",\"style_markup\":\"full\",\"target_style_markup\":\"disabled\",\"fields_style_markup\":\"disabled\"}}}",
  )
  inspect(
    logger_obj.get("min_level").unwrap().as_string().unwrap(),
    content="INFO",
  )
  inspect(logger_obj.get("target").unwrap().as_string().unwrap(), content="")
  inspect(
    logger_obj.get("timestamp").unwrap().as_bool().unwrap(),
    content="false",
  )
  inspect(logger_obj.get("queue") is None, content="true")
  inspect(sink_obj.get("kind").unwrap().as_string().unwrap(), content="console")
  inspect(sink_obj.get("path").unwrap().as_string().unwrap(), content="")
  inspect(sink_obj.get("append").unwrap().as_bool().unwrap(), content="true")
  inspect(
    sink_obj.get("auto_flush").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_timestamp").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_level").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_target").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("show_fields").unwrap().as_bool().unwrap(),
    content="true",
  )
  inspect(
    formatter_obj.get("separator").unwrap().as_string().unwrap(),
    content=" ",
  )
  inspect(
    formatter_obj.get("field_separator").unwrap().as_string().unwrap(),
    content=" ",
  )
  inspect(
    formatter_obj.get("template").unwrap().as_string().unwrap(),
    content="",
  )
  inspect(
    formatter_obj.get("color_mode").unwrap().as_string().unwrap(),
    content="never",
  )
  inspect(
    formatter_obj.get("color_support").unwrap().as_string().unwrap(),
    content="truecolor",
  )
  inspect(
    formatter_obj.get("style_markup").unwrap().as_string().unwrap(),
    content="full",
  )
  inspect(
    formatter_obj.get("target_style_markup").unwrap().as_string().unwrap(),
    content="disabled",
  )
  inspect(
    formatter_obj.get("fields_style_markup").unwrap().as_string().unwrap(),
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
