fn fields_to_json(fields : Array[Field]) -> Json {
  let obj : Map[String, Json] = {}
  for item in fields {
    obj[item.key] = Json::string(item.value)
  }
  Json::object(obj)
}

fn format_record(rec : Record) -> String {
  let prefix = if rec.timestamp_ms == 0UL {
    "[\{rec.level.label()}]"
  } else {
    "[\{rec.timestamp_ms.to_string()}] [\{rec.level.label()}]"
  }
  let base = if rec.target == "" {
    "\{prefix} \{rec.message}"
  } else {
    "\{prefix} [\{rec.target}] \{rec.message}"
  }
  if rec.fields.length() == 0 {
    base
  } else {
    let details = rec.fields.map(fn(f) { "\{f.key}=\{f.value}" }).join(" ")
    "\{base} \{details}"
  }
}

fn format_record_json(rec : Record) -> String {
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
