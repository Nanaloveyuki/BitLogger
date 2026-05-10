pub type RecordFormatter = (Record) -> String

pub(all) enum ColorMode {
  Never
  Auto
  Always
}

pub struct TextFormatter {
  show_timestamp : Bool
  show_level : Bool
  show_target : Bool
  show_fields : Bool
  separator : String
  field_separator : String
  template : String
  color_mode : ColorMode
}

pub fn text_formatter(
  show_timestamp~ : Bool = true,
  show_level~ : Bool = true,
  show_target~ : Bool = true,
  show_fields~ : Bool = true,
  separator~ : String = " ",
  field_separator~ : String = " ",
  template~ : String = "",
  color_mode~ : ColorMode = ColorMode::Never,
) -> TextFormatter {
  {
    show_timestamp,
    show_level,
    show_target,
    show_fields,
    separator,
    field_separator,
    template,
    color_mode,
  }
}

pub fn color_mode_label(mode : ColorMode) -> String {
  match mode {
    ColorMode::Never => "never"
    ColorMode::Auto => "auto"
    ColorMode::Always => "always"
  }
}

fn use_ansi_color(mode : ColorMode) -> Bool {
  match mode {
    ColorMode::Never => false
    ColorMode::Always => true
    ColorMode::Auto => match @env.get_env_var("NO_COLOR") {
      Some(_) => false
      None => true
    }
  }
}

fn ansi_wrap(text : String, code : String, enabled : Bool) -> String {
  if !enabled || text == "" {
    text
  } else {
    "\u{001b}[\{code}m\{text}\u{001b}[0m"
  }
}

fn level_ansi_code(level : Level) -> String {
  match level {
    Level::Trace => "90"
    Level::Debug => "36"
    Level::Info => "32"
    Level::Warn => "33"
    Level::Error => "31;1"
  }
}

fn fields_to_json(fields : Array[Field]) -> Json {
  let obj : Map[String, Json] = {}
  for item in fields {
    obj[item.key] = Json::string(item.value)
  }
  Json::object(obj)
}

fn format_fields(fields : Array[Field], separator : String) -> String {
  fields.map(fn(f) { "\{f.key}=\{f.value}" }).join(separator)
}

fn timestamp_text(rec : Record, formatter : TextFormatter) -> String {
  if formatter.show_timestamp && rec.timestamp_ms != 0UL {
    ansi_wrap(rec.timestamp_ms.to_string(), "90", use_ansi_color(formatter.color_mode))
  } else {
    ""
  }
}

fn level_text(rec : Record, formatter : TextFormatter) -> String {
  if formatter.show_level {
    ansi_wrap(rec.level.label(), level_ansi_code(rec.level), use_ansi_color(formatter.color_mode))
  } else {
    ""
  }
}

fn target_text(rec : Record, formatter : TextFormatter) -> String {
  if formatter.show_target && rec.target != "" {
    ansi_wrap(rec.target, "34", use_ansi_color(formatter.color_mode))
  } else {
    ""
  }
}

fn fields_text(rec : Record, formatter : TextFormatter) -> String {
  if formatter.show_fields && rec.fields.length() != 0 {
    ansi_wrap(format_fields(rec.fields, formatter.field_separator), "35", use_ansi_color(formatter.color_mode))
  } else {
    ""
  }
}

fn render_template(rec : Record, formatter : TextFormatter) -> String {
  formatter.template
    .replace_all(old="{timestamp}", new=timestamp_text(rec, formatter))
    .replace_all(old="{timestamp_ms}", new=timestamp_text(rec, formatter))
    .replace_all(old="{level}", new=level_text(rec, formatter))
    .replace_all(old="{target}", new=target_text(rec, formatter))
    .replace_all(old="{message}", new=rec.message)
    .replace_all(old="{fields}", new=fields_text(rec, formatter))
    .trim()
    .to_owned()
}

pub fn format_text(rec : Record, formatter~ : TextFormatter = text_formatter()) -> String {
  if formatter.template != "" {
    return render_template(rec, formatter)
  }
  let parts : Array[String] = []
  if formatter.show_timestamp && rec.timestamp_ms != 0UL {
    parts.push("[\{timestamp_text(rec, formatter)}]")
  }
  if formatter.show_level {
    parts.push("[\{level_text(rec, formatter)}]")
  }
  if formatter.show_target && rec.target != "" {
    parts.push("[\{target_text(rec, formatter)}]")
  }
  parts.push(rec.message)
  let base = parts.join(formatter.separator)
  if !formatter.show_fields || rec.fields.length() == 0 {
    base
  } else {
    let details = fields_text(rec, formatter)
    "\{base}\{formatter.separator}\{details}"
  }
}

pub fn format_json(rec : Record) -> String {
  let obj : Map[String, Json] = {
    "level": Json::string(rec.level.label()),
    "message": Json::string(rec.message),
    "fields": fields_to_json(rec.fields),
  }
  if rec.timestamp_ms != 0UL {
    obj["timestamp_ms"] = rec.timestamp_ms.to_json()
  }
  if rec.target == "" {
    Json::object(obj).stringify()
  } else {
    obj["target"] = Json::string(rec.target)
    Json::object(obj).stringify()
  }
}
