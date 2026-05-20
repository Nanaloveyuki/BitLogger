pub fn[S : Sink] Logger::log(
  self : Logger[S],
  level : Level,
  message : String,
  fields~ : Array[Field] = [],
  target? : String = "",
) -> Unit {
  if !self.is_enabled(level) {
    ()
  } else {
    let actual_target = if target == "" { self.target } else { target }
    let timestamp_ms = if self.timestamp { @env.now() } else { 0UL }
    self.sink.write(
      record(level, message, timestamp_ms=timestamp_ms, target=actual_target, fields=fields),
    )
  }
}

pub fn[S : Sink] Logger::trace(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {
  self.log(Level::Trace, message, fields=fields)
}

pub fn[S : Sink] Logger::debug(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {
  self.log(Level::Debug, message, fields=fields)
}

pub fn[S : Sink] Logger::info(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {
  self.log(Level::Info, message, fields=fields)
}

pub fn[S : Sink] Logger::warn(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {
  self.log(Level::Warn, message, fields=fields)
}

pub fn[S : Sink] Logger::error(self : Logger[S], message : String, fields~ : Array[Field] = []) -> Unit {
  self.log(Level::Error, message, fields=fields)
}
