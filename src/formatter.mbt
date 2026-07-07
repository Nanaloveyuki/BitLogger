///|
pub type RecordFormatter = @formatting.RecordFormatter

///|
pub type ColorMode = @formatting.ColorMode

///|
pub type ColorSupport = @formatting.ColorSupport

///|
pub type StyleMarkupMode = @formatting.StyleMarkupMode

///|
pub type TextStyle = @formatting.TextStyle

///|
pub fn text_style(
  fg? : String? = None,
  bg? : String? = None,
  bold? : Bool = false,
  dim? : Bool = false,
  italic? : Bool = false,
  underline? : Bool = false,
) -> TextStyle {
  @formatting.text_style(fg~, bg~, bold~, dim~, italic~, underline~)
}

///|
pub type StyleTagRegistry = @formatting.StyleTagRegistry

///|
pub fn style_tag_registry() -> StyleTagRegistry {
  @formatting.style_tag_registry()
}

///|
pub fn default_style_tag_registry() -> StyleTagRegistry {
  @formatting.default_style_tag_registry()
}

///|
pub fn global_style_tag_registry() -> StyleTagRegistry {
  @formatting.global_style_tag_registry()
}

///|
pub fn set_global_style_tag_registry(registry : StyleTagRegistry) -> Unit {
  @formatting.set_global_style_tag_registry(registry)
}

///|
pub fn reset_global_style_tag_registry() -> Unit {
  @formatting.reset_global_style_tag_registry()
}

///|
pub type TextFormatter = @formatting.TextFormatter

///|
pub fn text_formatter(
  show_timestamp? : Bool = true,
  show_level? : Bool = true,
  show_target? : Bool = true,
  show_fields? : Bool = true,
  separator? : String = " ",
  field_separator? : String = " ",
  template? : String = "",
  color_mode? : ColorMode = ColorMode::Never,
  color_support? : ColorSupport = ColorSupport::TrueColor,
  style_markup? : StyleMarkupMode = StyleMarkupMode::Full,
  target_style_markup? : StyleMarkupMode = StyleMarkupMode::Disabled,
  fields_style_markup? : StyleMarkupMode = StyleMarkupMode::Disabled,
  style_tags? : StyleTagRegistry? = None,
) -> TextFormatter {
  @formatting.text_formatter(
    show_timestamp~,
    show_level~,
    show_target~,
    show_fields~,
    separator~,
    field_separator~,
    template~,
    color_mode~,
    color_support~,
    style_markup~,
    target_style_markup~,
    fields_style_markup~,
    style_tags~,
  )
}

///|
pub fn color_support_label(support : ColorSupport) -> String {
  @formatting.color_support_label(support)
}

///|
pub fn style_markup_mode_label(mode : StyleMarkupMode) -> String {
  @formatting.style_markup_mode_label(mode)
}

///|
pub fn color_mode_label(mode : ColorMode) -> String {
  @formatting.color_mode_label(mode)
}

///|
pub fn format_text(
  rec : Record,
  formatter? : TextFormatter = text_formatter(),
) -> String {
  @formatting.format_text(rec, formatter~)
}

///|
pub fn format_json(rec : Record) -> String {
  @formatting.format_json(rec)
}
