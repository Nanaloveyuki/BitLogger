pub type RecordFormatter = (Record) -> String

pub(all) enum ColorMode {
  Never
  Auto
  Always
}

priv struct InlineStyle {
  fg_code : String?
  bold : Bool
  dim : Bool
  italic : Bool
  underline : Bool
}

priv struct StyledSegment {
  text : String
  style : InlineStyle
}

fn code_unit(ch : Char) -> Int {
  ch.to_int()
}

fn code_unit16(ch : UInt16) -> Int {
  ch.to_int()
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

fn ansi_wrap_with_style(text : String, style : InlineStyle, enabled : Bool) -> String {
  if !enabled || text == "" {
    text
  } else {
    let codes : Array[String] = []
    match style.fg_code {
      Some(code) => codes.push(code)
      None => ()
    }
    if style.bold {
      codes.push("1")
    }
    if style.dim {
      codes.push("2")
    }
    if style.italic {
      codes.push("3")
    }
    if style.underline {
      codes.push("4")
    }
    if codes.length() == 0 {
      text
    } else {
      let joined = codes.join(";")
      "\u{001b}[\{joined}m\{text}\u{001b}[0m"
    }
  }
}

fn default_inline_style() -> InlineStyle {
  { fg_code: None, bold: false, dim: false, italic: false, underline: false }
}

fn named_color_code(tag : String) -> String? {
  match tag {
    "black" => Some("30")
    "red" => Some("31")
    "green" => Some("32")
    "yellow" => Some("33")
    "blue" => Some("34")
    "magenta" => Some("35")
    "cyan" => Some("36")
    "white" => Some("37")
    "bright_black" => Some("90")
    "bright_red" => Some("91")
    "bright_green" => Some("92")
    "bright_yellow" => Some("93")
    "bright_blue" => Some("94")
    "bright_magenta" => Some("95")
    "bright_cyan" => Some("96")
    "bright_white" => Some("97")
    _ => None
  }
}

fn is_hex_color(value : String) -> Bool {
  if value.length() != 7 {
    return false
  }
  if value.unsafe_get(0) != '#' {
    return false
  }
  for i = 1; i < value.length(); i = i + 1 {
    let ch = value.unsafe_get(i)
    let is_digit = ch >= '0' && ch <= '9'
    let is_lower = ch >= 'a' && ch <= 'f'
    let is_upper = ch >= 'A' && ch <= 'F'
    if !(is_digit || is_lower || is_upper) {
      return false
    }
  }
  true
}

fn hex_to_int(ch : UInt16) -> Int {
  let code = code_unit16(ch)
  if code >= code_unit('0') && code <= code_unit('9') {
    code_unit16(ch) - code_unit('0')
  } else if code >= code_unit('a') && code <= code_unit('f') {
    code_unit16(ch) - code_unit('a') + 10
  } else {
    code_unit16(ch) - code_unit('A') + 10
  }
}

fn hex_pair_to_int(high : UInt16, low : UInt16) -> Int {
  hex_to_int(high) * 16 + hex_to_int(low)
}

fn rgb_fg_code(value : String) -> String {
  let r = hex_pair_to_int(value.unsafe_get(1), value.unsafe_get(2))
  let g = hex_pair_to_int(value.unsafe_get(3), value.unsafe_get(4))
  let b = hex_pair_to_int(value.unsafe_get(5), value.unsafe_get(6))
  "38;2;\{r};\{g};\{b}"
}

fn rgb_bg_code(value : String) -> String {
  let r = hex_pair_to_int(value.unsafe_get(4), value.unsafe_get(5))
  let g = hex_pair_to_int(value.unsafe_get(6), value.unsafe_get(7))
  let b = hex_pair_to_int(value.unsafe_get(8), value.unsafe_get(9))
  "48;2;\{r};\{g};\{b}"
}

fn apply_inline_tag(style : InlineStyle, tag : String) -> InlineStyle? {
  match tag {
    "b" => Some({ ..style, bold: true })
    "dim" => Some({ ..style, dim: true })
    "i" => Some({ ..style, italic: true })
    "u" => Some({ ..style, underline: true })
    _ => match named_color_code(tag) {
      Some(code) => Some({ ..style, fg_code: Some(code) })
      None => {
        if is_hex_color(tag) {
          Some({ ..style, fg_code: Some(rgb_fg_code(tag)) })
        } else if tag.length() == 10 && tag.has_prefix("bg:") && is_hex_color(tag[3:].to_owned()) {
          Some({ ..style, fg_code: Some(rgb_bg_code(tag)) })
        } else {
          None
        }
      }
    }
  }
}

fn push_plain_segment(
  segments : Array[StyledSegment],
  buffer : StringBuilder,
  style : InlineStyle,
) -> Unit {
  let text = buffer.to_string()
  if text != "" {
    segments.push({ text, style })
    buffer.reset()
  }
}

fn parse_inline_markup(input : String) -> Array[StyledSegment] {
  let segments : Array[StyledSegment] = []
  let buffer = StringBuilder::new()
  let stack : Array[InlineStyle] = [default_inline_style()]
  let chars = input.to_array()
  let current_style = fn() { stack[stack.length() - 1] }
  let flush = fn() { push_plain_segment(segments, buffer, current_style()) }
  let append_raw = fn(start : Int, finish : Int) {
    for i = start; i < finish; i = i + 1 {
      buffer.write_char(chars.unsafe_get(i))
    }
  }
  let find_tag_end = fn(start : Int) -> Int {
    for i = start; i < chars.length(); i = i + 1 {
      if chars.unsafe_get(i) == '>' {
        return i
      }
    }
    -1
  }
  for i = 0; i < chars.length(); {
    if chars.unsafe_get(i) != '<' {
      buffer.write_char(chars.unsafe_get(i))
      continue i + 1
    }
    let end = find_tag_end(i + 1)
    if end == -1 {
      buffer.write_char(chars[i])
      continue i + 1
    }
    let tag = input[i + 1:end].to_owned()
    if tag == "/" {
      if stack.length() > 1 {
        flush()
        ignore(stack.pop())
      } else {
        append_raw(i, end + 1)
      }
      continue end + 1
    }
    match apply_inline_tag(current_style(), tag) {
      Some(next_style) => {
        flush()
        stack.push(next_style)
      }
      None => append_raw(i, end + 1)
    }
    continue end + 1
  }
  flush()
  segments
}

fn render_inline_markup(message : String, formatter : TextFormatter) -> String {
  let enabled = use_ansi_color(formatter.color_mode)
  let segments = parse_inline_markup(message)
  let out = StringBuilder::new()
  for segment in segments {
    out.write_string(ansi_wrap_with_style(segment.text, segment.style, enabled))
  }
  out.to_string()
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
    .replace_all(old="{message}", new=render_inline_markup(rec.message, formatter))
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
  parts.push(render_inline_markup(rec.message, formatter))
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
