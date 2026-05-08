let default_console_sink : ConsoleSink = console_sink()
let default_min_level_ref : Ref[Level] = Ref::new(Level::Info)
let default_target_ref : Ref[String] = Ref::new("")

pub fn set_default_min_level(level : Level) -> Unit {
  default_min_level_ref.val = level
}

pub fn set_default_target(target : String) -> Unit {
  default_target_ref.val = target
}

pub fn default_logger() -> Logger[ConsoleSink] {
  Logger::new(default_console_sink, min_level=default_min_level_ref.val, target=default_target_ref.val)
}

pub fn log(level : Level, message : String, fields~ : Array[Field] = []) -> Unit {
  default_logger().log(level, message, fields=fields)
}

pub fn trace(message : String, fields~ : Array[Field] = []) -> Unit {
  default_logger().trace(message, fields=fields)
}

pub fn debug(message : String, fields~ : Array[Field] = []) -> Unit {
  default_logger().debug(message, fields=fields)
}

pub fn info(message : String, fields~ : Array[Field] = []) -> Unit {
  default_logger().info(message, fields=fields)
}

pub fn warn(message : String, fields~ : Array[Field] = []) -> Unit {
  default_logger().warn(message, fields=fields)
}

pub fn error(message : String, fields~ : Array[Field] = []) -> Unit {
  default_logger().error(message, fields=fields)
}
