///|
let default_console_sink : ConsoleSink = console_sink()

///|
let default_min_level_ref : Ref[Level] = Ref(Level::Info)

///|
let default_target_ref : Ref[String] = Ref("")

///|
pub fn set_default_min_level(level : Level) -> Unit {
  default_min_level_ref.val = level
}

///|
pub fn set_default_target(target : String) -> Unit {
  default_target_ref.val = target
}

///|
pub fn default_logger() -> Logger[ConsoleSink] {
  Logger::new(
    default_console_sink,
    min_level=default_min_level_ref.val,
    target=default_target_ref.val,
  )
}
