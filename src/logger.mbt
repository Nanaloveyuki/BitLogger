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

pub fn[S] Logger::bind(self : Logger[S], fields : Array[Field]) -> Logger[ContextSink[S]] {
  self.with_context_fields(fields)
}

pub fn[S] Logger::with_filter(self : Logger[S], predicate : (Record) -> Bool) -> Logger[FilterSink[S]] {
  {
    min_level: self.min_level,
    sink: filter_sink(self.sink, predicate),
    target: self.target,
    timestamp: self.timestamp,
  }
}

pub fn[S] Logger::with_patch(self : Logger[S], patch : RecordPatch) -> Logger[PatchSink[S]] {
  {
    min_level: self.min_level,
    sink: patch_sink(self.sink, patch),
    target: self.target,
    timestamp: self.timestamp,
  }
}

pub fn[S] Logger::with_queue(
  self : Logger[S],
  max_pending~ : Int = 0,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> Logger[QueuedSink[S]] {
  {
    min_level: self.min_level,
    sink: queued_sink(self.sink, max_pending=max_pending, overflow=overflow),
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
