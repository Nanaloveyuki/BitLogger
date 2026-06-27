///|
pub fn log(
  level : Level,
  message : String,
  fields? : Array[Field] = [],
) -> Unit {
  default_logger().log(level, message, fields~)
}

///|
pub fn trace(message : String, fields? : Array[Field] = []) -> Unit {
  default_logger().trace(message, fields~)
}

///|
pub fn debug(message : String, fields? : Array[Field] = []) -> Unit {
  default_logger().debug(message, fields~)
}

///|
pub fn info(message : String, fields? : Array[Field] = []) -> Unit {
  default_logger().info(message, fields~)
}

///|
pub fn warn(message : String, fields? : Array[Field] = []) -> Unit {
  default_logger().warn(message, fields~)
}

///|
pub fn error(message : String, fields? : Array[Field] = []) -> Unit {
  default_logger().error(message, fields~)
}
