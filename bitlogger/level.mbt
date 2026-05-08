pub(all) enum Level {
  Trace
  Debug
  Info
  Warn
  Error
}

pub fn Level::priority(self : Level) -> Int {
  match self {
    Level::Trace => 10
    Level::Debug => 20
    Level::Info => 30
    Level::Warn => 40
    Level::Error => 50
  }
}

pub fn Level::label(self : Level) -> String {
  match self {
    Level::Trace => "TRACE"
    Level::Debug => "DEBUG"
    Level::Info => "INFO"
    Level::Warn => "WARN"
    Level::Error => "ERROR"
  }
}

pub fn Level::enabled(self : Level, min_level : Level) -> Bool {
  self.priority() >= min_level.priority()
}
