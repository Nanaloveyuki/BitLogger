///|
pub(all) suberror ConfigError {
  InvalidConfig(String)
}

///|
pub(all) enum SinkKind {
  Console
  JsonConsole
  TextConsole
  File
}

///|
pub struct TextFormatterConfig {
  show_timestamp : Bool
  show_level : Bool
  show_target : Bool
  show_fields : Bool
  separator : String
  field_separator : String
  template : String
  color_mode : @formatting.ColorMode
  color_support : @formatting.ColorSupport
  style_markup : @formatting.StyleMarkupMode
  target_style_markup : @formatting.StyleMarkupMode
  fields_style_markup : @formatting.StyleMarkupMode
  style_tags : Map[String, @formatting.TextStyle]
}

///|
pub fn TextFormatterConfig::new(
  show_timestamp? : Bool = true,
  show_level? : Bool = true,
  show_target? : Bool = true,
  show_fields? : Bool = true,
  separator? : String = " ",
  field_separator? : String = " ",
  template? : String = "",
  color_mode? : @formatting.ColorMode = @formatting.ColorMode::Never,
  color_support? : @formatting.ColorSupport = @formatting.ColorSupport::TrueColor,
  style_markup? : @formatting.StyleMarkupMode = @formatting.StyleMarkupMode::Full,
  target_style_markup? : @formatting.StyleMarkupMode = @formatting.StyleMarkupMode::Disabled,
  fields_style_markup? : @formatting.StyleMarkupMode = @formatting.StyleMarkupMode::Disabled,
  style_tags? : Map[String, @formatting.TextStyle] = {},
) -> TextFormatterConfig {
  {
    show_timestamp,
    show_level,
    show_target,
    show_fields,
    separator,
    field_separator,
    template,
    color_mode,
    color_support,
    style_markup,
    target_style_markup,
    fields_style_markup,
    style_tags,
  }
}

///|
fn style_tag_registry_from_config(
  style_tags : Map[String, @formatting.TextStyle],
) -> @formatting.StyleTagRegistry {
  let registry = @formatting.style_tag_registry()
  for name, style in style_tags {
    ignore(registry.set_tag(name, style~))
  }
  registry
}

///|
pub fn TextFormatterConfig::to_formatter(
  self : TextFormatterConfig,
) -> @formatting.TextFormatter {
  @formatting.text_formatter(
    show_timestamp=self.show_timestamp,
    show_level=self.show_level,
    show_target=self.show_target,
    show_fields=self.show_fields,
    separator=self.separator,
    field_separator=self.field_separator,
    template=self.template,
    color_mode=self.color_mode,
    color_support=self.color_support,
    style_markup=self.style_markup,
    target_style_markup=self.target_style_markup,
    fields_style_markup=self.fields_style_markup,
    style_tags=if self.style_tags.length() == 0 {
      None
    } else {
      Some(style_tag_registry_from_config(self.style_tags))
    },
  )
}

///|
pub struct QueueConfig {
  max_pending : Int
  overflow : @queue_model.QueueOverflowPolicy
}

///|
pub fn QueueConfig::new(
  max_pending : Int,
  overflow? : @queue_model.QueueOverflowPolicy = @queue_model.QueueOverflowPolicy::DropNewest,
) -> QueueConfig {
  { max_pending, overflow }
}

///|
pub struct SinkConfig {
  kind : SinkKind
  path : String
  append : Bool
  auto_flush : Bool
  rotation : @file_model.FileRotation?
  text_formatter : TextFormatterConfig
}

///|
pub fn SinkConfig::new(
  kind? : SinkKind = SinkKind::Console,
  path? : String = "",
  append? : Bool = true,
  auto_flush? : Bool = true,
  rotation? : @file_model.FileRotation? = None,
  text_formatter? : TextFormatterConfig = default_text_formatter_config(),
) -> SinkConfig {
  { kind, path, append, auto_flush, rotation, text_formatter }
}

///|
pub struct LoggerConfig {
  min_level : @core.Level
  target : String
  timestamp : Bool
  sink : SinkConfig
  queue : QueueConfig?
}

///|
pub fn LoggerConfig::new(
  min_level? : @core.Level = @core.Level::Info,
  target? : String = "",
  timestamp? : Bool = false,
  sink? : SinkConfig = default_sink_config(),
  queue? : QueueConfig? = None,
) -> LoggerConfig {
  { min_level, target, timestamp, sink, queue }
}

///|
pub fn default_text_formatter_config() -> TextFormatterConfig {
  TextFormatterConfig::new()
}

///|
pub fn default_sink_config() -> SinkConfig {
  SinkConfig::new()
}

///|
pub fn default_logger_config() -> LoggerConfig {
  LoggerConfig::new()
}

///|
fn expect_object(
  value : @json_parser.JsonValue,
  context : String,
) -> Map[String, @json_parser.JsonValue] raise ConfigError {
  match value.as_object() {
    Some(obj) => obj
    None => raise ConfigError::InvalidConfig("Expected object at " + context)
  }
}

///|
fn get_string(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
  default? : String = "",
) -> String raise ConfigError {
  match obj.get(key) {
    None => default
    Some(value) =>
      match value.as_string() {
        Some(text) => text
        None =>
          raise ConfigError::InvalidConfig("Expected string at key " + key)
      }
  }
}

///|
fn get_optional_string(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
) -> String? raise ConfigError {
  match obj.get(key) {
    None => None
    Some(value) =>
      match value.as_string() {
        Some(text) => Some(text)
        None =>
          raise ConfigError::InvalidConfig("Expected string at key " + key)
      }
  }
}

///|
fn get_bool(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
  default~ : Bool,
) -> Bool raise ConfigError {
  match obj.get(key) {
    None => default
    Some(value) =>
      match value.as_bool() {
        Some(flag) => flag
        None => raise ConfigError::InvalidConfig("Expected bool at key " + key)
      }
  }
}

///|
fn get_int(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
  default~ : Int,
) -> Int raise ConfigError {
  match obj.get(key) {
    None => default
    Some(value) =>
      match value.as_number() {
        Some(number) => number.to_int()
        None =>
          raise ConfigError::InvalidConfig("Expected number at key " + key)
      }
  }
}

///|
fn get_optional_int64_string(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
) -> Int64? raise ConfigError {
  match obj.get(key) {
    None => None
    Some(value) =>
      match value.as_string() {
        Some(text) =>
          Some(
            @string.parse_int64(text) catch {
              _ =>
                raise ConfigError::InvalidConfig(
                  "Expected int64 string at key " + key,
                )
            },
          )
        None =>
          raise ConfigError::InvalidConfig("Expected string at key " + key)
      }
  }
}

///|
fn parse_level(name : String) -> @core.Level raise ConfigError {
  match name.to_upper() {
    "TRACE" => @core.Level::Trace
    "DEBUG" => @core.Level::Debug
    "INFO" => @core.Level::Info
    "WARN" => @core.Level::Warn
    "ERROR" => @core.Level::Error
    _ => raise ConfigError::InvalidConfig("Unsupported level: " + name)
  }
}

///|
fn parse_overflow(
  name : String,
) -> @queue_model.QueueOverflowPolicy raise ConfigError {
  match name.to_upper() {
    "DROPNEWEST" => @queue_model.QueueOverflowPolicy::DropNewest
    "DROPPOLDEST" => @queue_model.QueueOverflowPolicy::DropOldest
    "DROPOLDEST" => @queue_model.QueueOverflowPolicy::DropOldest
    _ =>
      raise ConfigError::InvalidConfig(
        "Unsupported queue overflow policy: " + name,
      )
  }
}

///|
fn parse_sink_kind(name : String) -> SinkKind raise ConfigError {
  match name.to_upper() {
    "CONSOLE" => SinkKind::Console
    "JSON_CONSOLE" => SinkKind::JsonConsole
    "JSONCONSOLE" => SinkKind::JsonConsole
    "TEXT_CONSOLE" => SinkKind::TextConsole
    "TEXTCONSOLE" => SinkKind::TextConsole
    "FILE" => SinkKind::File
    _ => raise ConfigError::InvalidConfig("Unsupported sink kind: " + name)
  }
}

///|
fn parse_color_mode(name : String) -> @formatting.ColorMode raise ConfigError {
  match name.to_upper() {
    "NEVER" => @formatting.ColorMode::Never
    "AUTO" => @formatting.ColorMode::Auto
    "ALWAYS" => @formatting.ColorMode::Always
    _ => raise ConfigError::InvalidConfig("Unsupported color mode: " + name)
  }
}

///|
fn parse_color_support(
  name : String,
) -> @formatting.ColorSupport raise ConfigError {
  match name.to_upper() {
    "BASIC" => @formatting.ColorSupport::Basic
    "TRUECOLOR" => @formatting.ColorSupport::TrueColor
    _ => raise ConfigError::InvalidConfig("Unsupported color support: " + name)
  }
}

///|
fn parse_style_markup_mode(
  name : String,
) -> @formatting.StyleMarkupMode raise ConfigError {
  match name.to_upper() {
    "DISABLED" => @formatting.StyleMarkupMode::Disabled
    "BUILTIN" => @formatting.StyleMarkupMode::Builtin
    "FULL" => @formatting.StyleMarkupMode::Full
    _ =>
      raise ConfigError::InvalidConfig("Unsupported style markup mode: " + name)
  }
}

///|
fn sink_kind_label(kind : SinkKind) -> String {
  match kind {
    SinkKind::Console => "console"
    SinkKind::JsonConsole => "json_console"
    SinkKind::TextConsole => "text_console"
    SinkKind::File => "file"
  }
}

///|
fn parse_text_formatter_config(
  value : @json_parser.JsonValue,
) -> TextFormatterConfig raise ConfigError {
  let obj = expect_object(value, "text_formatter")
  TextFormatterConfig::new(
    show_timestamp=get_bool(obj, "show_timestamp", default=true),
    show_level=get_bool(obj, "show_level", default=true),
    show_target=get_bool(obj, "show_target", default=true),
    show_fields=get_bool(obj, "show_fields", default=true),
    separator=get_string(obj, "separator", default=" "),
    field_separator=get_string(obj, "field_separator", default=" "),
    template=get_string(obj, "template", default=""),
    color_mode=parse_color_mode(get_string(obj, "color_mode", default="never")),
    color_support=parse_color_support(
      get_string(obj, "color_support", default="truecolor"),
    ),
    style_markup=parse_style_markup_mode(
      get_string(obj, "style_markup", default="full"),
    ),
    target_style_markup=parse_style_markup_mode(
      get_string(obj, "target_style_markup", default="disabled"),
    ),
    fields_style_markup=parse_style_markup_mode(
      get_string(obj, "fields_style_markup", default="disabled"),
    ),
    style_tags=match obj.get("style_tags") {
      None => {}
      Some(inner) => parse_style_tags_config(inner)
    },
  )
}

///|
fn parse_text_style_config(
  value : @json_parser.JsonValue,
  context : String,
) -> @formatting.TextStyle raise ConfigError {
  let obj = expect_object(value, context)
  @formatting.text_style(
    fg=get_optional_string(obj, "fg"),
    bg=get_optional_string(obj, "bg"),
    bold=get_bool(obj, "bold", default=false),
    dim=get_bool(obj, "dim", default=false),
    italic=get_bool(obj, "italic", default=false),
    underline=get_bool(obj, "underline", default=false),
  )
}

///|
fn parse_style_tags_config(
  value : @json_parser.JsonValue,
) -> Map[String, @formatting.TextStyle] raise ConfigError {
  let obj = expect_object(value, "text_formatter.style_tags")
  let style_tags : Map[String, @formatting.TextStyle] = {}
  for name, item in obj {
    style_tags[name] = parse_text_style_config(
      item,
      "text_formatter.style_tags." + name,
    )
  }
  style_tags
}

///|
fn parse_queue_config(
  value : @json_parser.JsonValue,
) -> QueueConfig raise ConfigError {
  let obj = expect_object(value, "queue")
  QueueConfig::new(
    get_int(obj, "max_pending", default=0),
    overflow=parse_overflow(get_string(obj, "overflow", default="DropNewest")),
  )
}

///|
fn parse_file_rotation_config(
  value : @json_parser.JsonValue,
) -> @file_model.FileRotation raise ConfigError {
  let obj = expect_object(value, "sink.rotation")
  let max_backups = get_int(obj, "max_backups", default=1)
  match get_optional_int64_string(obj, "max_bytes_i64") {
    Some(max_bytes_i64) =>
      @file_model.file_rotation_i64(max_bytes_i64, max_backups~)
    None =>
      @file_model.file_rotation(
        get_int(obj, "max_bytes", default=1),
        max_backups~,
      )
  }
}

///|
fn parse_sink_config(
  value : @json_parser.JsonValue,
) -> SinkConfig raise ConfigError {
  let obj = expect_object(value, "sink")
  let kind = parse_sink_kind(get_string(obj, "kind", default="console"))
  let formatter = match obj.get("text_formatter") {
    None => default_text_formatter_config()
    Some(inner) => parse_text_formatter_config(inner)
  }
  let path = get_string(obj, "path", default="")
  match kind {
    SinkKind::File =>
      if path == "" {
        raise ConfigError::InvalidConfig("File sink requires non-empty path")
      }
    _ => ()
  }
  SinkConfig::new(
    kind~,
    path~,
    append=get_bool(obj, "append", default=true),
    auto_flush=get_bool(obj, "auto_flush", default=true),
    rotation=match obj.get("rotation") {
      None => None
      Some(inner) => Some(parse_file_rotation_config(inner))
    },
    text_formatter=formatter,
  )
}

///|
pub fn parse_logger_config_text(
  input : String,
) -> LoggerConfig raise ConfigError {
  let root = @json_parser.parse(input) catch {
    e => raise ConfigError::InvalidConfig("Invalid JSON: " + e.to_string())
  }
  let obj = expect_object(root, "root")
  LoggerConfig::new(
    min_level=parse_level(get_string(obj, "min_level", default="INFO")),
    target=get_string(obj, "target", default=""),
    timestamp=get_bool(obj, "timestamp", default=false),
    sink=match obj.get("sink") {
      None => default_sink_config()
      Some(value) => parse_sink_config(value)
    },
    queue=match obj.get("queue") {
      None => None
      Some(value) => Some(parse_queue_config(value))
    },
  )
}

///|
pub fn queue_config_to_json(queue : QueueConfig) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "max_pending": @json_parser.JsonValue::Number(queue.max_pending.to_double()),
    "overflow": @json_parser.JsonValue::String(
      match queue.overflow {
        @queue_model.QueueOverflowPolicy::DropNewest => "DropNewest"
        @queue_model.QueueOverflowPolicy::DropOldest => "DropOldest"
      },
    ),
  })
}

///|
pub fn stringify_queue_config(
  queue : QueueConfig,
  pretty? : Bool = false,
) -> String {
  let value = queue_config_to_json(queue)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

///|
pub fn text_formatter_config_to_json(
  config : TextFormatterConfig,
) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "show_timestamp": @json_parser.JsonValue::Bool(config.show_timestamp),
    "show_level": @json_parser.JsonValue::Bool(config.show_level),
    "show_target": @json_parser.JsonValue::Bool(config.show_target),
    "show_fields": @json_parser.JsonValue::Bool(config.show_fields),
    "separator": @json_parser.JsonValue::String(config.separator),
    "field_separator": @json_parser.JsonValue::String(config.field_separator),
    "template": @json_parser.JsonValue::String(config.template),
    "color_mode": @json_parser.JsonValue::String(
      @formatting.color_mode_label(config.color_mode),
    ),
    "color_support": @json_parser.JsonValue::String(
      @formatting.color_support_label(config.color_support),
    ),
    "style_markup": @json_parser.JsonValue::String(
      @formatting.style_markup_mode_label(config.style_markup),
    ),
    "target_style_markup": @json_parser.JsonValue::String(
      @formatting.style_markup_mode_label(config.target_style_markup),
    ),
    "fields_style_markup": @json_parser.JsonValue::String(
      @formatting.style_markup_mode_label(config.fields_style_markup),
    ),
  }
  if config.style_tags.length() != 0 {
    obj["style_tags"] = style_tags_config_to_json(config.style_tags)
  }
  @json_parser.JsonValue::Object(obj)
}

///|
fn text_style_config_to_json(
  style : @formatting.TextStyle,
) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "bold": @json_parser.JsonValue::Bool(style.bold),
    "dim": @json_parser.JsonValue::Bool(style.dim),
    "italic": @json_parser.JsonValue::Bool(style.italic),
    "underline": @json_parser.JsonValue::Bool(style.underline),
  }
  match style.fg {
    Some(value) => obj["fg"] = @json_parser.JsonValue::String(value)
    None => ()
  }
  match style.bg {
    Some(value) => obj["bg"] = @json_parser.JsonValue::String(value)
    None => ()
  }
  @json_parser.JsonValue::Object(obj)
}

///|
fn style_tags_config_to_json(
  style_tags : Map[String, @formatting.TextStyle],
) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {}
  for name, style in style_tags {
    obj[name] = text_style_config_to_json(style)
  }
  @json_parser.JsonValue::Object(obj)
}

///|
pub fn stringify_text_formatter_config(
  config : TextFormatterConfig,
  pretty? : Bool = false,
) -> String {
  let value = text_formatter_config_to_json(config)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

///|
pub fn sink_config_to_json(config : SinkConfig) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "kind": @json_parser.JsonValue::String(sink_kind_label(config.kind)),
    "path": @json_parser.JsonValue::String(config.path),
    "append": @json_parser.JsonValue::Bool(config.append),
    "auto_flush": @json_parser.JsonValue::Bool(config.auto_flush),
    "text_formatter": text_formatter_config_to_json(config.text_formatter),
  }
  match config.rotation {
    None => ()
    Some(rotation) =>
      obj["rotation"] = @file_model.file_rotation_config_to_json(rotation)
  }
  @json_parser.JsonValue::Object(obj)
}

///|
pub fn stringify_sink_config(
  config : SinkConfig,
  pretty? : Bool = false,
) -> String {
  let value = sink_config_to_json(config)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

///|
pub fn logger_config_to_json(config : LoggerConfig) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "min_level": @json_parser.JsonValue::String(config.min_level.label()),
    "target": @json_parser.JsonValue::String(config.target),
    "timestamp": @json_parser.JsonValue::Bool(config.timestamp),
    "sink": sink_config_to_json(config.sink),
  }
  match config.queue {
    None => ()
    Some(queue) => obj["queue"] = queue_config_to_json(queue)
  }
  @json_parser.JsonValue::Object(obj)
}

///|
pub fn stringify_logger_config(
  config : LoggerConfig,
  pretty? : Bool = false,
) -> String {
  let value = logger_config_to_json(config)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}
