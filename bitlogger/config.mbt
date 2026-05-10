pub(all) suberror ConfigError {
  InvalidConfig(String)
}

pub(all) enum SinkKind {
  Console
  JsonConsole
  TextConsole
  File
}

pub struct TextFormatterConfig {
  show_timestamp : Bool
  show_level : Bool
  show_target : Bool
  show_fields : Bool
  separator : String
  field_separator : String
  template : String
}

pub fn TextFormatterConfig::new(
  show_timestamp~ : Bool = true,
  show_level~ : Bool = true,
  show_target~ : Bool = true,
  show_fields~ : Bool = true,
  separator~ : String = " ",
  field_separator~ : String = " ",
  template~ : String = "",
) -> TextFormatterConfig {
  {
    show_timestamp,
    show_level,
    show_target,
    show_fields,
    separator,
    field_separator,
    template,
  }
}

pub fn TextFormatterConfig::to_formatter(self : TextFormatterConfig) -> TextFormatter {
  text_formatter(
    show_timestamp=self.show_timestamp,
    show_level=self.show_level,
    show_target=self.show_target,
    show_fields=self.show_fields,
    separator=self.separator,
    field_separator=self.field_separator,
    template=self.template,
  )
}

pub struct QueueConfig {
  max_pending : Int
  overflow : QueueOverflowPolicy
}

pub fn QueueConfig::new(
  max_pending : Int,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueueConfig {
  { max_pending, overflow }
}

pub struct SinkConfig {
  kind : SinkKind
  path : String
  append : Bool
  auto_flush : Bool
  rotation : FileRotation?
  text_formatter : TextFormatterConfig
}

pub fn SinkConfig::new(
  kind~ : SinkKind = SinkKind::Console,
  path~ : String = "",
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> SinkConfig {
  {
    kind,
    path,
    append,
    auto_flush,
    rotation,
    text_formatter,
  }
}

pub struct LoggerConfig {
  min_level : Level
  target : String
  timestamp : Bool
  sink : SinkConfig
  queue : QueueConfig?
}

pub fn LoggerConfig::new(
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  sink~ : SinkConfig = default_sink_config(),
  queue~ : QueueConfig? = None,
) -> LoggerConfig {
  {
    min_level,
    target,
    timestamp,
    sink,
    queue,
  }
}

pub fn default_text_formatter_config() -> TextFormatterConfig {
  TextFormatterConfig::new()
}

pub fn default_sink_config() -> SinkConfig {
  SinkConfig::new()
}

pub fn default_logger_config() -> LoggerConfig {
  LoggerConfig::new()
}

pub(all) enum RuntimeSink {
  Console(ConsoleSink)
  JsonConsole(JsonConsoleSink)
  TextConsole(FormattedConsoleSink)
  File(FileSink)
  QueuedConsole(QueuedSink[ConsoleSink])
  QueuedJsonConsole(QueuedSink[JsonConsoleSink])
  QueuedTextConsole(QueuedSink[FormattedConsoleSink])
  QueuedFile(QueuedSink[FileSink])
}

pub impl Sink for RuntimeSink with write(self, rec) {
  match self {
    Console(sink) => sink.write(rec)
    JsonConsole(sink) => sink.write(rec)
    TextConsole(sink) => sink.write(rec)
    File(sink) => sink.write(rec)
    QueuedConsole(sink) => sink.write(rec)
    QueuedJsonConsole(sink) => sink.write(rec)
    QueuedTextConsole(sink) => sink.write(rec)
    QueuedFile(sink) => sink.write(rec)
  }
}

pub fn RuntimeSink::flush(self : RuntimeSink) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(sink) => if sink.flush() { 1 } else { 0 }
    QueuedConsole(sink) => sink.flush()
    QueuedJsonConsole(sink) => sink.flush()
    QueuedTextConsole(sink) => sink.flush()
    QueuedFile(sink) => sink.flush()
  }
}

pub fn RuntimeSink::drain(self : RuntimeSink, max_items~ : Int = -1) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(sink) => if sink.flush() { 1 } else { 0 }
    QueuedConsole(sink) => sink.drain(max_items=max_items)
    QueuedJsonConsole(sink) => sink.drain(max_items=max_items)
    QueuedTextConsole(sink) => sink.drain(max_items=max_items)
    QueuedFile(sink) => sink.drain(max_items=max_items)
  }
}

pub fn RuntimeSink::close(self : RuntimeSink) -> Bool {
  match self {
    Console(_) => true
    JsonConsole(_) => true
    TextConsole(_) => true
    File(sink) => sink.close()
    QueuedConsole(_) => true
    QueuedJsonConsole(_) => true
    QueuedTextConsole(_) => true
    QueuedFile(sink) => sink.sink.close()
  }
}

pub fn RuntimeSink::pending_count(self : RuntimeSink) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(_) => 0
    QueuedConsole(sink) => sink.pending_count()
    QueuedJsonConsole(sink) => sink.pending_count()
    QueuedTextConsole(sink) => sink.pending_count()
    QueuedFile(sink) => sink.pending_count()
  }
}

pub fn RuntimeSink::dropped_count(self : RuntimeSink) -> Int {
  match self {
    Console(_) => 0
    JsonConsole(_) => 0
    TextConsole(_) => 0
    File(_) => 0
    QueuedConsole(sink) => sink.dropped_count()
    QueuedJsonConsole(sink) => sink.dropped_count()
    QueuedTextConsole(sink) => sink.dropped_count()
    QueuedFile(sink) => sink.dropped_count()
  }
}

pub fn RuntimeSink::file_available(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.is_available()
    QueuedFile(sink) => sink.sink.is_available()
    _ => false
  }
}

pub fn RuntimeSink::file_reopen(self : RuntimeSink, append~ : Bool? = None) -> Bool {
  match self {
    File(sink) => sink.reopen(append=append)
    QueuedFile(sink) => sink.sink.reopen(append=append)
    _ => false
  }
}

pub fn RuntimeSink::file_append_mode(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.append_mode()
    QueuedFile(sink) => sink.sink.append_mode()
    _ => false
  }
}

pub fn RuntimeSink::file_path(self : RuntimeSink) -> String {
  match self {
    File(sink) => sink.path()
    QueuedFile(sink) => sink.sink.path()
    _ => ""
  }
}

pub fn RuntimeSink::file_auto_flush(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.auto_flush_enabled()
    QueuedFile(sink) => sink.sink.auto_flush_enabled()
    _ => false
  }
}

pub fn RuntimeSink::file_rotation_enabled(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.rotation_enabled()
    QueuedFile(sink) => sink.sink.rotation_enabled()
    _ => false
  }
}

pub fn RuntimeSink::file_rotation_config(self : RuntimeSink) -> FileRotation? {
  match self {
    File(sink) => sink.rotation_config()
    QueuedFile(sink) => sink.sink.rotation_config()
    _ => None
  }
}

pub fn RuntimeSink::file_flush(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.flush()
    QueuedFile(sink) => {
      ignore(sink.flush())
      sink.sink.flush()
    }
    _ => false
  }
}

pub fn RuntimeSink::file_close(self : RuntimeSink) -> Bool {
  match self {
    File(sink) => sink.close()
    QueuedFile(sink) => {
      ignore(sink.flush())
      sink.sink.close()
    }
    _ => false
  }
}

pub fn RuntimeSink::file_open_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.open_failures()
    QueuedFile(sink) => sink.sink.open_failures()
    _ => 0
  }
}

pub fn RuntimeSink::file_write_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.write_failures()
    QueuedFile(sink) => sink.sink.write_failures()
    _ => 0
  }
}

pub fn RuntimeSink::file_flush_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.flush_failures()
    QueuedFile(sink) => sink.sink.flush_failures()
    _ => 0
  }
}

pub fn RuntimeSink::file_rotation_failures(self : RuntimeSink) -> Int {
  match self {
    File(sink) => sink.rotation_failures()
    QueuedFile(sink) => sink.sink.rotation_failures()
    _ => 0
  }
}

pub type ConfiguredLogger = Logger[RuntimeSink]

pub fn ConfiguredLogger::flush(self : ConfiguredLogger) -> Int {
  self.sink.flush()
}

pub fn ConfiguredLogger::drain(self : ConfiguredLogger, max_items~ : Int = -1) -> Int {
  self.sink.drain(max_items=max_items)
}

pub fn ConfiguredLogger::close(self : ConfiguredLogger) -> Bool {
  self.sink.close()
}

pub fn ConfiguredLogger::pending_count(self : ConfiguredLogger) -> Int {
  self.sink.pending_count()
}

pub fn ConfiguredLogger::dropped_count(self : ConfiguredLogger) -> Int {
  self.sink.dropped_count()
}

pub fn ConfiguredLogger::file_available(self : ConfiguredLogger) -> Bool {
  self.sink.file_available()
}

pub fn ConfiguredLogger::file_reopen(self : ConfiguredLogger, append~ : Bool? = None) -> Bool {
  self.sink.file_reopen(append=append)
}

pub fn ConfiguredLogger::file_append_mode(self : ConfiguredLogger) -> Bool {
  self.sink.file_append_mode()
}

pub fn ConfiguredLogger::file_path(self : ConfiguredLogger) -> String {
  self.sink.file_path()
}

pub fn ConfiguredLogger::file_auto_flush(self : ConfiguredLogger) -> Bool {
  self.sink.file_auto_flush()
}

pub fn ConfiguredLogger::file_rotation_enabled(self : ConfiguredLogger) -> Bool {
  self.sink.file_rotation_enabled()
}

pub fn ConfiguredLogger::file_rotation_config(self : ConfiguredLogger) -> FileRotation? {
  self.sink.file_rotation_config()
}

pub fn ConfiguredLogger::file_flush(self : ConfiguredLogger) -> Bool {
  self.sink.file_flush()
}

pub fn ConfiguredLogger::file_close(self : ConfiguredLogger) -> Bool {
  self.sink.file_close()
}

pub fn ConfiguredLogger::file_open_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_open_failures()
}

pub fn ConfiguredLogger::file_write_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_write_failures()
}

pub fn ConfiguredLogger::file_flush_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_flush_failures()
}

pub fn ConfiguredLogger::file_rotation_failures(self : ConfiguredLogger) -> Int {
  self.sink.file_rotation_failures()
}

fn expect_object(
  value : @json_parser.JsonValue,
  context : String,
) -> Map[String, @json_parser.JsonValue] raise ConfigError {
  match value.as_object() {
    Some(obj) => obj
    None => raise ConfigError::InvalidConfig("Expected object at " + context)
  }
}

fn get_string(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
  default~ : String = "",
) -> String raise ConfigError {
  match obj.get(key) {
    None => default
    Some(value) => match value.as_string() {
      Some(text) => text
      None => raise ConfigError::InvalidConfig("Expected string at key " + key)
    }
  }
}

fn get_bool(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
  default~ : Bool,
) -> Bool raise ConfigError {
  match obj.get(key) {
    None => default
    Some(value) => match value.as_bool() {
      Some(flag) => flag
      None => raise ConfigError::InvalidConfig("Expected bool at key " + key)
    }
  }
}

fn get_int(
  obj : Map[String, @json_parser.JsonValue],
  key : String,
  default~ : Int,
) -> Int raise ConfigError {
  match obj.get(key) {
    None => default
    Some(value) => match value.as_number() {
      Some(number) => number.to_int()
      None => raise ConfigError::InvalidConfig("Expected number at key " + key)
    }
  }
}

fn parse_level(name : String) -> Level raise ConfigError {
  match name.to_upper() {
    "TRACE" => Level::Trace
    "DEBUG" => Level::Debug
    "INFO" => Level::Info
    "WARN" => Level::Warn
    "ERROR" => Level::Error
    _ => raise ConfigError::InvalidConfig("Unsupported level: " + name)
  }
}

fn parse_overflow(name : String) -> QueueOverflowPolicy raise ConfigError {
  match name.to_upper() {
    "DROPNEWEST" => QueueOverflowPolicy::DropNewest
    "DROPPOLDEST" => QueueOverflowPolicy::DropOldest
    "DROPOLDEST" => QueueOverflowPolicy::DropOldest
    _ => raise ConfigError::InvalidConfig("Unsupported queue overflow policy: " + name)
  }
}

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

fn sink_kind_label(kind : SinkKind) -> String {
  match kind {
    SinkKind::Console => "console"
    SinkKind::JsonConsole => "json_console"
    SinkKind::TextConsole => "text_console"
    SinkKind::File => "file"
  }
}

fn parse_text_formatter_config(value : @json_parser.JsonValue) -> TextFormatterConfig raise ConfigError {
  let obj = expect_object(value, "text_formatter")
  TextFormatterConfig::new(
    show_timestamp=get_bool(obj, "show_timestamp", default=true),
    show_level=get_bool(obj, "show_level", default=true),
    show_target=get_bool(obj, "show_target", default=true),
    show_fields=get_bool(obj, "show_fields", default=true),
    separator=get_string(obj, "separator", default=" "),
    field_separator=get_string(obj, "field_separator", default=" "),
    template=get_string(obj, "template", default=""),
  )
}

fn parse_queue_config(value : @json_parser.JsonValue) -> QueueConfig raise ConfigError {
  let obj = expect_object(value, "queue")
  QueueConfig::new(
    get_int(obj, "max_pending", default=0),
    overflow=parse_overflow(get_string(obj, "overflow", default="DropNewest")),
  )
}

fn parse_file_rotation_config(value : @json_parser.JsonValue) -> FileRotation raise ConfigError {
  let obj = expect_object(value, "sink.rotation")
  file_rotation(
    get_int(obj, "max_bytes", default=1),
    max_backups=get_int(obj, "max_backups", default=1),
  )
}

fn parse_sink_config(value : @json_parser.JsonValue) -> SinkConfig raise ConfigError {
  let obj = expect_object(value, "sink")
  let kind = parse_sink_kind(get_string(obj, "kind", default="console"))
  let formatter = match obj.get("text_formatter") {
    None => default_text_formatter_config()
    Some(inner) => parse_text_formatter_config(inner)
  }
  let path = get_string(obj, "path", default="")
  match kind {
    SinkKind::File => if path == "" {
      raise ConfigError::InvalidConfig("File sink requires non-empty path")
    }
    _ => ()
  }
  SinkConfig::new(
    kind=kind,
    path=path,
    append=get_bool(obj, "append", default=true),
    auto_flush=get_bool(obj, "auto_flush", default=true),
    rotation=match obj.get("rotation") {
      None => None
      Some(inner) => Some(parse_file_rotation_config(inner))
    },
    text_formatter=formatter,
  )
}

pub fn parse_logger_config_text(input : String) -> LoggerConfig raise ConfigError {
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

fn queue_config_to_json(queue : QueueConfig) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "max_pending": @json_parser.JsonValue::Number(queue.max_pending.to_double()),
    "overflow": @json_parser.JsonValue::String(match queue.overflow {
      QueueOverflowPolicy::DropNewest => "DropNewest"
      QueueOverflowPolicy::DropOldest => "DropOldest"
    }),
  })
}

fn text_formatter_config_to_json(config : TextFormatterConfig) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "show_timestamp": @json_parser.JsonValue::Bool(config.show_timestamp),
    "show_level": @json_parser.JsonValue::Bool(config.show_level),
    "show_target": @json_parser.JsonValue::Bool(config.show_target),
    "show_fields": @json_parser.JsonValue::Bool(config.show_fields),
    "separator": @json_parser.JsonValue::String(config.separator),
    "field_separator": @json_parser.JsonValue::String(config.field_separator),
    "template": @json_parser.JsonValue::String(config.template),
  })
}

fn file_rotation_config_to_json(config : FileRotation) -> @json_parser.JsonValue {
  @json_parser.JsonValue::Object({
    "max_bytes": @json_parser.JsonValue::Number(config.max_bytes.to_double()),
    "max_backups": @json_parser.JsonValue::Number(config.max_backups.to_double()),
  })
}

fn sink_config_to_json(config : SinkConfig) -> @json_parser.JsonValue {
  let obj : Map[String, @json_parser.JsonValue] = {
    "kind": @json_parser.JsonValue::String(sink_kind_label(config.kind)),
    "path": @json_parser.JsonValue::String(config.path),
    "append": @json_parser.JsonValue::Bool(config.append),
    "auto_flush": @json_parser.JsonValue::Bool(config.auto_flush),
    "text_formatter": text_formatter_config_to_json(config.text_formatter),
  }
  match config.rotation {
    None => ()
    Some(rotation) => obj["rotation"] = file_rotation_config_to_json(rotation)
  }
  @json_parser.JsonValue::Object(obj)
}

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

pub fn stringify_logger_config(config : LoggerConfig, pretty~ : Bool = false) -> String {
  let value = logger_config_to_json(config)
  if pretty {
    @json_parser.stringify_pretty(value, 2)
  } else {
    @json_parser.stringify(value)
  }
}

fn build_runtime_sink(config : SinkConfig) -> RuntimeSink {
  match config.kind {
    SinkKind::Console => RuntimeSink::Console(console_sink())
    SinkKind::JsonConsole => RuntimeSink::JsonConsole(json_console_sink())
    SinkKind::TextConsole => RuntimeSink::TextConsole(
      text_console_sink(config.text_formatter.to_formatter()),
    )
    SinkKind::File => RuntimeSink::File(
      file_sink(
        config.path,
        append=config.append,
        auto_flush=config.auto_flush,
        rotation=config.rotation,
        formatter=fn(rec) {
          format_text(rec, formatter=config.text_formatter.to_formatter())
        },
      ),
    )
  }
}

fn apply_queue_config(sink : RuntimeSink, queue : QueueConfig) -> RuntimeSink {
  match sink {
    Console(inner) => RuntimeSink::QueuedConsole(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    JsonConsole(inner) => RuntimeSink::QueuedJsonConsole(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    TextConsole(inner) => RuntimeSink::QueuedTextConsole(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    File(inner) => RuntimeSink::QueuedFile(
      queued_sink(inner, max_pending=queue.max_pending, overflow=queue.overflow),
    )
    QueuedConsole(_) => sink
    QueuedJsonConsole(_) => sink
    QueuedTextConsole(_) => sink
    QueuedFile(_) => sink
  }
}

pub fn build_logger(config : LoggerConfig) -> ConfiguredLogger {
  let sink = build_runtime_sink(config.sink)
  let actual_sink = match config.queue {
    None => sink
    Some(queue) => apply_queue_config(sink, queue)
  }
  Logger::new(actual_sink, min_level=config.min_level, target=config.target)
    .with_timestamp(enabled=config.timestamp)
}

pub fn parse_and_build_logger(input : String) -> ConfiguredLogger raise ConfigError {
  build_logger(parse_logger_config_text(input))
}
