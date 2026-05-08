pub(all) suberror AsyncLoggerClosed {
  AsyncLoggerClosed
}

pub(all) enum AsyncOverflowPolicy {
  Blocking
  DropOldest
  DropNewest
}

pub struct AsyncLoggerConfig {
  max_pending : Int
  overflow : AsyncOverflowPolicy
}

pub fn AsyncLoggerConfig::new(
  max_pending~ : Int = 0,
  overflow~ : AsyncOverflowPolicy = AsyncOverflowPolicy::Blocking,
) -> AsyncLoggerConfig {
  { max_pending, overflow }
}

pub struct AsyncLogger[S] {
  min_level : @bitlogger.Level
  target : String
  timestamp : Bool
  overflow : AsyncOverflowPolicy
  sink : S
  context_fields : Array[@bitlogger.Field]
  filter : (@bitlogger.Record) -> Bool
  patch : @bitlogger.RecordPatch
  queue : @async.Queue[@bitlogger.Record]
  pending_count : Ref[Int]
  dropped_count : Ref[Int]
}

pub fn[S] async_logger(
  sink : S,
  config~ : AsyncLoggerConfig = AsyncLoggerConfig::new(),
  min_level~ : @bitlogger.Level = @bitlogger.Level::Info,
  target~ : String = "",
) -> AsyncLogger[S] {
  {
    min_level,
    target,
    timestamp: false,
    overflow: config.overflow,
    sink,
    context_fields: [],
    filter: fn(_) { true },
    patch: @bitlogger.identity_patch(),
    queue: @async.Queue::new(kind=queue_kind_of(config)),
    pending_count: Ref::new(0),
    dropped_count: Ref::new(0),
  }
}

fn queue_kind_of(config : AsyncLoggerConfig) -> @aqueue.Kind {
  let limit = if config.max_pending < 0 { 0 } else { config.max_pending }
  match config.overflow {
    AsyncOverflowPolicy::Blocking => @aqueue.Kind::Blocking(limit)
    AsyncOverflowPolicy::DropOldest => @aqueue.Kind::DiscardOldest(limit)
    AsyncOverflowPolicy::DropNewest => @aqueue.Kind::DiscardLatest(limit)
  }
}

pub fn[S] AsyncLogger::with_timestamp(self : AsyncLogger[S], enabled~ : Bool = true) -> AsyncLogger[S] {
  { ..self, timestamp: enabled }
}

pub fn[S] AsyncLogger::with_target(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {
  { ..self, target }
}

pub fn[S] AsyncLogger::with_context_fields(
  self : AsyncLogger[S],
  fields : Array[@bitlogger.Field],
) -> AsyncLogger[S] {
  { ..self, context_fields: fields }
}

pub fn[S] AsyncLogger::with_filter(
  self : AsyncLogger[S],
  predicate : (@bitlogger.Record) -> Bool,
) -> AsyncLogger[S] {
  let current = self.filter
  {
    ..self,
    filter: fn(rec) {
      current(rec) && predicate(rec)
    },
  }
}

pub fn[S] AsyncLogger::with_patch(
  self : AsyncLogger[S],
  patch : @bitlogger.RecordPatch,
) -> AsyncLogger[S] {
  let current = self.patch
  {
    ..self,
    patch: fn(rec) {
      patch(current(rec))
    },
  }
}

pub fn[S] AsyncLogger::with_min_level(
  self : AsyncLogger[S],
  min_level : @bitlogger.Level,
) -> AsyncLogger[S] {
  { ..self, min_level }
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

pub fn[S] AsyncLogger::child(self : AsyncLogger[S], target : String) -> AsyncLogger[S] {
  { ..self, target: combine_targets(self.target, target) }
}

pub fn[S] AsyncLogger::is_enabled(self : AsyncLogger[S], level : @bitlogger.Level) -> Bool {
  level.enabled(self.min_level)
}

pub async fn[S] AsyncLogger::log(
  self : AsyncLogger[S],
  level : @bitlogger.Level,
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
  target? : String = "",
) -> Unit {
  guard self.is_enabled(level) else {
    ()
  }
  let actual_target = if target == "" { self.target } else { target }
  let timestamp_ms = if self.timestamp { @env.now() } else { 0UL }
  let rec = @bitlogger.Record::new(
    level,
    message,
    timestamp_ms=timestamp_ms,
    target=actual_target,
    fields=merge_fields(self.context_fields, fields),
  )
  let rec = (self.patch)(rec)
  guard (self.filter)(rec) else {
    ()
  }
  let accepted = self.queue.try_put(rec) catch {
    err if err is AsyncLoggerClosed => false
    err => raise err
  }
  if accepted {
    self.pending_count.val += 1
  } else {
    match self.overflow {
      AsyncOverflowPolicy::Blocking => {
        self.queue.put(rec) catch {
          err if err is AsyncLoggerClosed => ()
          err => raise err
        }
        self.pending_count.val += 1
      }
      AsyncOverflowPolicy::DropOldest | AsyncOverflowPolicy::DropNewest => {
        self.dropped_count.val += 1
      }
    }
  }
}

fn merge_fields(
  left : Array[@bitlogger.Field],
  right : Array[@bitlogger.Field],
) -> Array[@bitlogger.Field] {
  if left.length() == 0 {
    right
  } else if right.length() == 0 {
    left
  } else {
    left + right
  }
}

pub async fn[S] AsyncLogger::trace(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Trace, message, fields=fields)
}

pub async fn[S] AsyncLogger::debug(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Debug, message, fields=fields)
}

pub async fn[S] AsyncLogger::info(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Info, message, fields=fields)
}

pub async fn[S] AsyncLogger::warn(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Warn, message, fields=fields)
}

pub async fn[S] AsyncLogger::error(
  self : AsyncLogger[S],
  message : String,
  fields~ : Array[@bitlogger.Field] = [],
) -> Unit {
  self.log(@bitlogger.Level::Error, message, fields=fields)
}

pub fn[S] AsyncLogger::pending_count(self : AsyncLogger[S]) -> Int {
  self.pending_count.val
}

pub fn[S] AsyncLogger::dropped_count(self : AsyncLogger[S]) -> Int {
  self.dropped_count.val
}

pub fn[S] AsyncLogger::close(self : AsyncLogger[S], clear? : Bool = false) -> Unit {
  self.queue.close(error=AsyncLoggerClosed, clear=clear)
}

pub async fn[S] AsyncLogger::wait_idle(self : AsyncLogger[S]) -> Unit {
  while self.pending_count() > 0 {
    @async.pause()
  }
}

pub async fn[S : @bitlogger.Sink] AsyncLogger::run(self : AsyncLogger[S]) -> Unit {
  while true {
    let rec = self.queue.get() catch {
      err if err is AsyncLoggerClosed => break
      err => raise err
    }
    self.sink.write(rec)
    if self.pending_count.val > 0 {
      self.pending_count.val -= 1
    }
  }
}
