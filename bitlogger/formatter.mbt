pub type RecordFormatter = (Record) -> String

pub struct TextFormatter {
  show_timestamp : Bool
  show_level : Bool
  show_target : Bool
  show_fields : Bool
  separator : String
  field_separator : String
  template : String
}

pub fn text_formatter(
  show_timestamp~ : Bool = true,
  show_level~ : Bool = true,
  show_target~ : Bool = true,
  show_fields~ : Bool = true,
  separator~ : String = " ",
  field_separator~ : String = " ",
  template~ : String = "",
) -> TextFormatter {
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
    rec.timestamp_ms.to_string()
  } else {
    ""
  }
}

fn level_text(rec : Record, formatter : TextFormatter) -> String {
  if formatter.show_level {
    rec.level.label()
  } else {
    ""
  }
}

fn target_text(rec : Record, formatter : TextFormatter) -> String {
  if formatter.show_target && rec.target != "" {
    rec.target
  } else {
    ""
  }
}

fn fields_text(rec : Record, formatter : TextFormatter) -> String {
  if formatter.show_fields && rec.fields.length() != 0 {
    format_fields(rec.fields, formatter.field_separator)
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
    parts.push("[\{rec.timestamp_ms.to_string()}]")
  }
  if formatter.show_level {
    parts.push("[\{rec.level.label()}]")
  }
  if formatter.show_target && rec.target != "" {
    parts.push("[\{rec.target}]")
  }
  parts.push(rec.message)
  let base = parts.join(formatter.separator)
  if !formatter.show_fields || rec.fields.length() == 0 {
    base
  } else {
    let details = format_fields(rec.fields, formatter.field_separator)
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
