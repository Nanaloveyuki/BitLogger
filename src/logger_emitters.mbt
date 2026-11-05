///|
pub fn[S : Sink] Logger::log(
  self : Logger[S],
  level : Level,
  message : String,
  fields~ : Array[Field] = [],
  target~ : String = "",
) -> Unit {
  if !self.is_enabled(level) {
    ()
  } else {
    let actual_target = if target == "" { self.target } else { target }
    let timestamp_ms = if self.timestamp { @env.now() } else { 0UL }
    self.sink.write(
      record(level, message, timestamp_ms~, target=actual_target, fields~),
    )
  }
}

///|
/// Emits a record through a caller-supplied writer and returns its typed result.
pub fn[S, E] Logger::log_with(
  self : Logger[S],
  level : Level,
  message : String,
  write : (S, Record) -> Result[Unit, E],
  fields~ : Array[Field] = [],
  target~ : String = "",
) -> Result[Unit, E] {
  if !self.is_enabled(level) {
    Ok(())
  } else {
    let actual_target = if target == "" { self.target } else { target }
    let timestamp_ms = if self.timestamp { @env.now() } else { 0UL }
    write(
      self.sink,
      record(level, message, timestamp_ms~, target=actual_target, fields~),
    )
  }
}

///|
pub fn[S : Sink] Logger::trace(
  self : Logger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
  self.log(Level::Trace, message, fields~)
}

///|
pub fn[S : Sink] Logger::debug(
  self : Logger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
  self.log(Level::Debug, message, fields~)
}

///|
pub fn[S : Sink] Logger::info(
  self : Logger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
  self.log(Level::Info, message, fields~)
}

///|
pub fn[S : Sink] Logger::warn(
  self : Logger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
  self.log(Level::Warn, message, fields~)
}

///|
pub fn[S : Sink] Logger::error(
  self : Logger[S],
  message : String,
  fields~ : Array[Field] = [],
) -> Unit {
  self.log(Level::Error, message, fields~)
}
