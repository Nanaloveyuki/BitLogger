pub struct Logger[S] {
  min_level : Level
  sink : S
  target : String
  timestamp : Bool
}

pub fn[S] Logger::new(sink : S, min_level~ : Level = Level::Info, target~ : String = "") -> Logger[S] {
  { min_level, sink, target, timestamp: false }
}

pub fn[S] Logger::with_target(self : Logger[S], target : String) -> Logger[S] {
  { ..self, target }
}

fn combine_targets(parent : String, child : String) -> String {
  if parent == "" {
    child
  } else if child == "" {
    parent
  } else {
    "\{parent}.\{child}"
  }
}

pub fn[S] Logger::child(self : Logger[S], target : String) -> Logger[S] {
  { ..self, target: combine_targets(self.target, target) }
}

pub fn[S] Logger::with_context_fields(self : Logger[S], fields : Array[Field]) -> Logger[ContextSink[S]] {
  {
    min_level: self.min_level,
    sink: ContextSink::{ sink: self.sink, context_fields: fields },
    target: self.target,
    timestamp: self.timestamp,
  }
}

pub fn[S] Logger::with_min_level(self : Logger[S], min_level : Level) -> Logger[S] {
  { ..self, min_level }
}

pub fn[S] Logger::with_timestamp(self : Logger[S], enabled~ : Bool = true) -> Logger[S] {
  { ..self, timestamp: enabled }
}

pub fn[S] Logger::is_enabled(self : Logger[S], level : Level) -> Bool {
  level.enabled(self.min_level)
}

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
