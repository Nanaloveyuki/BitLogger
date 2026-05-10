pub type RecordFormatter = (Record) -> String

pub(all) enum ColorMode {
  Never
  Auto
  Always
}

pub(all) enum StyleMarkupMode {
  Disabled
  Builtin
  Full
}

pub struct TextStyle {
  fg : String?
  bg : String?
  bold : Bool
  dim : Bool
  italic : Bool
  underline : Bool
}

pub fn text_style(
  fg~ : String? = None,
  bg~ : String? = None,
  bold~ : Bool = false,
  dim~ : Bool = false,
  italic~ : Bool = false,
  underline~ : Bool = false,
) -> TextStyle {
  { fg, bg, bold, dim, italic, underline }
}

pub struct StyleTagRegistry {
  entries : Map[String, TextStyle]
}

fn normalize_style_tag_name(name : String) -> String {
  name.trim().to_lower().to_owned()
}

pub fn style_tag_registry() -> StyleTagRegistry {
  { entries: {} }
}

fn merge_text_style(base : TextStyle, overlay : TextStyle) -> TextStyle {
  {
    fg: match overlay.fg {
      Some(_) => overlay.fg
      None => base.fg
    },
    bg: match overlay.bg {
      Some(_) => overlay.bg
      None => base.bg
    },
    bold: base.bold || overlay.bold,
    dim: base.dim || overlay.dim,
    italic: base.italic || overlay.italic,
    underline: base.underline || overlay.underline,
  }
}

pub fn StyleTagRegistry::set_tag(
  self : StyleTagRegistry,
  name : String,
  style~ : TextStyle = text_style(),
  fg~ : String? = None,
  bg~ : String? = None,
  bold~ : Bool = false,
  dim~ : Bool = false,
  italic~ : Bool = false,
  underline~ : Bool = false,
) -> StyleTagRegistry {
  let overlay = text_style(fg=fg, bg=bg, bold=bold, dim=dim, italic=italic, underline=underline)
  self.entries[normalize_style_tag_name(name)] = merge_text_style(style, overlay)
  self
}

pub fn StyleTagRegistry::get(self : StyleTagRegistry, name : String) -> TextStyle? {
  self.entries.get(normalize_style_tag_name(name))
}

pub fn StyleTagRegistry::contains(self : StyleTagRegistry, name : String) -> Bool {
  self.entries.contains(normalize_style_tag_name(name))
}

pub fn StyleTagRegistry::define_alias(
  self : StyleTagRegistry,
  name : String,
  target : String,
) -> StyleTagRegistry {
  match self.get(target) {
    Some(style) => self.set_tag(name, style=style)
    None => match global_style_tag_registry().get(target) {
      Some(style) => self.set_tag(name, style=style)
      None => match builtin_text_style_for_tag(normalize_style_tag_name(target)) {
        Some(style) => self.set_tag(name, style=style)
        None => self
      }
    }
  }
}

pub fn default_style_tag_registry() -> StyleTagRegistry {
  style_tag_registry()
    .set_tag("black", fg=Some("black"))
    .set_tag("red", fg=Some("red"))
    .set_tag("green", fg=Some("green"))
    .set_tag("yellow", fg=Some("yellow"))
    .set_tag("blue", fg=Some("blue"))
    .set_tag("magenta", fg=Some("magenta"))
    .set_tag("cyan", fg=Some("cyan"))
    .set_tag("white", fg=Some("white"))
    .set_tag("bright_black", fg=Some("bright_black"))
    .set_tag("bright_red", fg=Some("bright_red"))
    .set_tag("bright_green", fg=Some("bright_green"))
    .set_tag("bright_yellow", fg=Some("bright_yellow"))
    .set_tag("bright_blue", fg=Some("bright_blue"))
    .set_tag("bright_magenta", fg=Some("bright_magenta"))
    .set_tag("bright_cyan", fg=Some("bright_cyan"))
    .set_tag("bright_white", fg=Some("bright_white"))
    .set_tag("b", bold=true)
    .set_tag("dim", dim=true)
    .set_tag("i", italic=true)
    .set_tag("u", underline=true)
}

let global_style_tag_registry_ref : Ref[StyleTagRegistry] = Ref::new(style_tag_registry())

pub fn global_style_tag_registry() -> StyleTagRegistry {
  global_style_tag_registry_ref.val
}

pub fn set_global_style_tag_registry(registry : StyleTagRegistry) -> Unit {
  global_style_tag_registry_ref.val = registry
}

pub fn reset_global_style_tag_registry() -> Unit {
  global_style_tag_registry_ref.val = style_tag_registry()
}

priv struct InlineStyle {
  fg_code : String?
  bg_code : String?
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
  style_markup : StyleMarkupMode
  style_tags : StyleTagRegistry?
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
  style_markup~ : StyleMarkupMode = StyleMarkupMode::Full,
  style_tags~ : StyleTagRegistry? = None,
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
    style_markup,
    style_tags,
  }
}

pub fn style_markup_mode_label(mode : StyleMarkupMode) -> String {
  match mode {
    StyleMarkupMode::Disabled => "disabled"
    StyleMarkupMode::Builtin => "builtin"
    StyleMarkupMode::Full => "full"
  }
}

pub fn TextFormatter::with_style_markup(self : TextFormatter, style_markup : StyleMarkupMode) -> TextFormatter {
  { ..self, style_markup }
}

pub fn TextFormatter::without_style_markup(self : TextFormatter) -> TextFormatter {
  { ..self, style_markup: StyleMarkupMode::Disabled }
}

pub fn TextFormatter::with_style_tags(self : TextFormatter, style_tags : StyleTagRegistry) -> TextFormatter {
  { ..self, style_tags: Some(style_tags) }
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
    match style.bg_code {
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
  { fg_code: None, bg_code: None, bold: false, dim: false, italic: false, underline: false }
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

fn named_bg_color_code(tag : String) -> String? {
  match tag {
    "black" => Some("40")
    "red" => Some("41")
    "green" => Some("42")
    "yellow" => Some("43")
    "blue" => Some("44")
    "magenta" => Some("45")
    "cyan" => Some("46")
    "white" => Some("47")
    "bright_black" => Some("100")
    "bright_red" => Some("101")
    "bright_green" => Some("102")
    "bright_yellow" => Some("103")
    "bright_blue" => Some("104")
    "bright_magenta" => Some("105")
    "bright_cyan" => Some("106")
    "bright_white" => Some("107")
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

fn rgb_bg_code_from_hex(value : String) -> String {
  let r = hex_pair_to_int(value.unsafe_get(1), value.unsafe_get(2))
  let g = hex_pair_to_int(value.unsafe_get(3), value.unsafe_get(4))
  let b = hex_pair_to_int(value.unsafe_get(5), value.unsafe_get(6))
  "48;2;\{r};\{g};\{b}"
}

fn inline_style_from_text_style(base : InlineStyle, style : TextStyle) -> InlineStyle? {
  let fg_code = match style.fg {
    None => Some(base.fg_code)
    Some(value) => match named_color_code(normalize_style_tag_name(value)) {
      Some(code) => Some(Some(code))
      None => if is_hex_color(value) {
        Some(Some(rgb_fg_code(value)))
      } else {
        None
      }
    }
  }
  let bg_code = match style.bg {
    None => Some(base.bg_code)
    Some(value) => match named_bg_color_code(normalize_style_tag_name(value)) {
      Some(code) => Some(Some(code))
      None => if is_hex_color(value) {
        Some(Some(rgb_bg_code_from_hex(value)))
      } else {
        None
      }
    }
  }
  match fg_code {
    Some(next_fg) => match bg_code {
      Some(next_bg) => Some({
        fg_code: next_fg,
        bg_code: next_bg,
        bold: base.bold || style.bold,
        dim: base.dim || style.dim,
        italic: base.italic || style.italic,
        underline: base.underline || style.underline,
      })
      None => None
    }
    None => None
  }
}

fn builtin_text_style_for_tag(tag : String) -> TextStyle? {
  match normalize_style_tag_name(tag) {
    "black" => Some(text_style(fg=Some("black")))
    "red" => Some(text_style(fg=Some("red")))
    "green" => Some(text_style(fg=Some("green")))
    "yellow" => Some(text_style(fg=Some("yellow")))
    "blue" => Some(text_style(fg=Some("blue")))
    "magenta" => Some(text_style(fg=Some("magenta")))
    "cyan" => Some(text_style(fg=Some("cyan")))
    "white" => Some(text_style(fg=Some("white")))
    "bright_black" => Some(text_style(fg=Some("bright_black")))
    "bright_red" => Some(text_style(fg=Some("bright_red")))
    "bright_green" => Some(text_style(fg=Some("bright_green")))
    "bright_yellow" => Some(text_style(fg=Some("bright_yellow")))
    "bright_blue" => Some(text_style(fg=Some("bright_blue")))
    "bright_magenta" => Some(text_style(fg=Some("bright_magenta")))
    "bright_cyan" => Some(text_style(fg=Some("bright_cyan")))
    "bright_white" => Some(text_style(fg=Some("bright_white")))
    "b" => Some(text_style(bold=true))
    "dim" => Some(text_style(dim=true))
    "i" => Some(text_style(italic=true))
    "u" => Some(text_style(underline=true))
    _ => None
  }
}

fn resolve_registered_text_style(tag : String, formatter : TextFormatter) -> TextStyle? {
  let normalized = normalize_style_tag_name(tag)
  match formatter.style_markup {
    StyleMarkupMode::Builtin => return builtin_text_style_for_tag(normalized)
    _ => ()
  }
  match formatter.style_tags {
    Some(registry) => match registry.get(normalized) {
      Some(style) => Some(style)
      None => match global_style_tag_registry().get(normalized) {
        Some(style) => Some(style)
        None => builtin_text_style_for_tag(normalized)
      }
    }
    None => match global_style_tag_registry().get(normalized) {
      Some(style) => Some(style)
      None => builtin_text_style_for_tag(normalized)
    }
  }
}

fn apply_inline_tag(style : InlineStyle, tag : String, formatter : TextFormatter) -> InlineStyle? {
  let normalized = normalize_style_tag_name(tag)
  if is_hex_color(tag) {
    Some({ ..style, fg_code: Some(rgb_fg_code(tag)) })
  } else if normalized.length() == 10 && normalized.has_prefix("bg:") && is_hex_color(normalized[3:].to_owned()) {
    Some({ ..style, bg_code: Some(rgb_bg_code(normalized)) })
  } else {
    match resolve_registered_text_style(normalized, formatter) {
      Some(spec) => inline_style_from_text_style(style, spec)
      None => None
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

fn parse_inline_markup(input : String, formatter : TextFormatter) -> Array[StyledSegment] {
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
    match apply_inline_tag(current_style(), tag, formatter) {
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
  match formatter.style_markup {
    StyleMarkupMode::Disabled => return message
    _ => ()
  }
  let enabled = use_ansi_color(formatter.color_mode)
  let segments = parse_inline_markup(message, formatter)
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
