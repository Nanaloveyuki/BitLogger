pub trait Sink {
  write(Self, Record) -> Unit
}

pub struct ConsoleSink {
  _dummy : Unit
}

pub fn console_sink() -> ConsoleSink {
  { _dummy: () }
}

pub impl Sink for ConsoleSink with write(self, rec) {
  ignore(self)
  println(format_text(rec))
}

pub struct ContextSink[S] {
  sink : S
  context_fields : Array[Field]
}

pub impl[S : Sink] Sink for ContextSink[S] with write(self, rec) {
  let merged = if self.context_fields.length() == 0 {
    rec.fields
  } else if rec.fields.length() == 0 {
    self.context_fields
  } else {
    self.context_fields + rec.fields
  }
  self.sink.write({ ..rec, fields: merged })
}

pub struct JsonConsoleSink {
  _dummy : Unit
}

pub fn json_console_sink() -> JsonConsoleSink {
  { _dummy: () }
}

pub impl Sink for JsonConsoleSink with write(self, rec) {
  ignore(self)
  println(format_json(rec))
}

pub struct FileSink {
  path : String
  append : Ref[Bool]
  handle : Ref[FileHandle?]
  formatter : RecordFormatter
  auto_flush : Bool
  rotation : FileRotation?
  open_failures : Ref[Int]
  write_failures : Ref[Int]
  flush_failures : Ref[Int]
  rotation_failures : Ref[Int]
}

pub struct FileRotation {
  max_bytes : Int
  max_backups : Int
}

pub fn file_rotation(max_bytes : Int, max_backups~ : Int = 1) -> FileRotation {
  {
    max_bytes: if max_bytes <= 0 { 1 } else { max_bytes },
    max_backups: if max_backups <= 0 { 1 } else { max_backups },
  }
}

pub fn native_files_supported() -> Bool {
  native_files_supported_internal()
}

pub fn file_sink(
  path : String,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  formatter~ : RecordFormatter = fn(rec) {
    format_text(rec)
  },
) -> FileSink {
  let handle = open_file_handle_internal(path, append)
  {
    path,
    append: Ref::new(append),
    handle: Ref::new(handle),
    formatter,
    auto_flush,
    rotation,
    open_failures: Ref::new(if handle is Some(_) { 0 } else { 1 }),
    write_failures: Ref::new(0),
    flush_failures: Ref::new(0),
    rotation_failures: Ref::new(0),
  }
}

pub fn FileSink::is_available(self : FileSink) -> Bool {
  self.handle.val is Some(_)
}

pub fn FileSink::flush(self : FileSink) -> Bool {
  match self.handle.val {
    None => false
    Some(handle) => {
      let ok = flush_file_handle_internal(handle)
      if !ok {
        self.flush_failures.val += 1
      }
      ok
    }
  }
}

pub fn FileSink::append_mode(self : FileSink) -> Bool {
  self.append.val
}

pub fn FileSink::path(self : FileSink) -> String {
  self.path
}

pub fn FileSink::auto_flush_enabled(self : FileSink) -> Bool {
  self.auto_flush
}

pub fn FileSink::close(self : FileSink) -> Bool {
  match self.handle.val {
    None => false
    Some(handle) => {
      let ok = close_file_handle_internal(handle)
      self.handle.val = None
      ok
    }
  }
}

pub fn FileSink::rotation_failures(self : FileSink) -> Int {
  self.rotation_failures.val
}

pub fn FileSink::open_failures(self : FileSink) -> Int {
  self.open_failures.val
}

pub fn FileSink::write_failures(self : FileSink) -> Int {
  self.write_failures.val
}

pub fn FileSink::flush_failures(self : FileSink) -> Int {
  self.flush_failures.val
}

pub fn FileSink::reopen(self : FileSink, append~ : Bool? = None) -> Bool {
  let append_mode = append.unwrap_or(self.append.val)
  self.append.val = append_mode
  match self.handle.val {
    None => ()
    Some(handle) => {
      ignore(close_file_handle_internal(handle))
      self.handle.val = None
    }
  }
  let reopened = open_file_handle_internal(self.path, append_mode)
  self.handle.val = reopened
  if reopened is Some(_) {
    true
  } else {
    self.open_failures.val += 1
    false
  }
}

fn rotated_file_path(path : String, index : Int) -> String {
  "\{path}.\{index}"
}

fn rotate_file_sink_internal(sink : FileSink, rotation : FileRotation) -> Bool {
  let closed = match sink.handle.val {
    None => true
    Some(handle) => {
      let ok = close_file_handle_internal(handle)
      sink.handle.val = None
      ok
    }
  }
  if !closed {
    return false
  }
  if rotation.max_backups > 0 {
    ignore(remove_file_internal(rotated_file_path(sink.path, rotation.max_backups)))
    for index = rotation.max_backups - 1; index >= 1; {
      let from_path = rotated_file_path(sink.path, index)
      let to_path = rotated_file_path(sink.path, index + 1)
      ignore(rename_file_internal(from_path, to_path))
      continue index - 1
    }
    ignore(rename_file_internal(sink.path, rotated_file_path(sink.path, 1)))
  } else {
    ignore(remove_file_internal(sink.path))
  }
  sink.handle.val = open_file_handle_internal(sink.path, false)
  sink.handle.val is Some(_)
}

fn rotate_if_needed_internal(sink : FileSink, next_line_bytes : Int) -> Bool {
  match sink.rotation {
    None => true
    Some(rotation) => match sink.handle.val {
      None => false
      Some(handle) => {
        let size = file_size_internal(handle)
        if size + next_line_bytes <= rotation.max_bytes {
          true
        } else {
          let rotated = rotate_file_sink_internal(sink, rotation)
          if !rotated {
            sink.rotation_failures.val += 1
          }
          rotated
        }
      }
    }
  }
}

pub impl Sink for FileSink with write(self, rec) {
  match self.handle.val {
    None => {
      self.write_failures.val += 1
    }
    Some(_) => {
      let line = "\{(self.formatter)(rec)}\n"
      let can_write = rotate_if_needed_internal(self, string_byte_length_internal(line))
      if can_write {
        match self.handle.val {
          None => {
            self.write_failures.val += 1
          }
          Some(active) => {
            let wrote = write_file_handle_internal(active, line)
            if wrote {
              if self.auto_flush {
                let flushed = flush_file_handle_internal(active)
                if !flushed {
                  self.flush_failures.val += 1
                }
              }
            } else {
              self.write_failures.val += 1
            }
          }
        }
      } else {
        self.write_failures.val += 1
      }
    }
  }
}

pub struct FormattedConsoleSink {
  formatter : RecordFormatter
}

pub fn formatted_console_sink(formatter : RecordFormatter) -> FormattedConsoleSink {
  { formatter, }
}

pub fn text_console_sink(formatter : TextFormatter) -> FormattedConsoleSink {
  formatted_console_sink(fn(rec) {
    format_text(rec, formatter=formatter)
  })
}

pub impl Sink for FormattedConsoleSink with write(self, rec) {
  println((self.formatter)(rec))
}

pub struct FormattedCallbackSink {
  formatter : RecordFormatter
  callback : (String) -> Unit
}

pub fn formatted_callback_sink(
  formatter : RecordFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
  { formatter, callback }
}

pub fn text_callback_sink(
  formatter : TextFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
  formatted_callback_sink(fn(rec) {
    format_text(rec, formatter=formatter)
  }, callback)
}

pub impl Sink for FormattedCallbackSink with write(self, rec) {
  (self.callback)((self.formatter)(rec))
}

pub struct FanoutSink[A, B] {
  left : A
  right : B
}

pub fn[A, B] fanout_sink(left : A, right : B) -> FanoutSink[A, B] {
  { left, right }
}

pub impl[A : Sink, B : Sink] Sink for FanoutSink[A, B] with write(self, rec) {
  self.left.write(rec)
  self.right.write({ ..rec })
}

pub struct SplitSink[A, B] {
  left : A
  right : B
  predicate : (Record) -> Bool
}

pub fn[A, B] split_sink(left : A, right : B, predicate : (Record) -> Bool) -> SplitSink[A, B] {
  { left, right, predicate }
}

pub fn[A, B] split_by_level(
  left : A,
  right : B,
  min_level~ : Level = Level::Warn,
) -> SplitSink[A, B] {
  split_sink(left, right, fn(rec) {
    rec.level.enabled(min_level)
  })
}

pub impl[A : Sink, B : Sink] Sink for SplitSink[A, B] with write(self, rec) {
  if (self.predicate)(rec) {
    self.left.write(rec)
  } else {
    self.right.write(rec)
  }
}

pub struct CallbackSink {
  callback : (Record) -> Unit
}

pub fn callback_sink(callback : (Record) -> Unit) -> CallbackSink {
  { callback, }
}

pub impl Sink for CallbackSink with write(self, rec) {
  (self.callback)(rec)
}

pub struct BufferedSink[S] {
  sink : S
  buffer : Ref[Array[Record]]
  flush_limit : Int
}

pub fn[S] buffered_sink(sink : S, flush_limit~ : Int = 1) -> BufferedSink[S] {
  let actual_limit = if flush_limit <= 0 { 1 } else { flush_limit }
  { sink, buffer: Ref::new([]), flush_limit: actual_limit }
}

pub fn[S] BufferedSink::pending_count(self : BufferedSink[S]) -> Int {
  self.buffer.val.length()
}

pub fn[S : Sink] BufferedSink::flush(self : BufferedSink[S]) -> Unit {
  if self.buffer.val.length() == 0 {
    ()
  } else {
    let pending = self.buffer.val
    self.buffer.val = []
    for rec in pending {
      self.sink.write(rec)
    }
  }
}

pub impl[S : Sink] Sink for BufferedSink[S] with write(self, rec) {
  self.buffer.val.push(rec)
  if self.buffer.val.length() >= self.flush_limit {
    self.flush()
  }
}

pub(all) enum QueueOverflowPolicy {
  DropNewest
  DropOldest
}

pub struct QueuedSink[S] {
  sink : S
  queue : @queue.Queue[Record]
  max_pending : Int
  overflow : QueueOverflowPolicy
  dropped_count : Ref[Int]
}

pub fn[S] queued_sink(
  sink : S,
  max_pending~ : Int = 0,
  overflow~ : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueuedSink[S] {
  {
    sink,
    queue: @queue.Queue::new(),
    max_pending,
    overflow,
    dropped_count: Ref::new(0),
  }
}

pub fn[S] QueuedSink::pending_count(self : QueuedSink[S]) -> Int {
  self.queue.length()
}

pub fn[S] QueuedSink::dropped_count(self : QueuedSink[S]) -> Int {
  self.dropped_count.val
}

pub fn[S : Sink] QueuedSink::drain(self : QueuedSink[S], max_items~ : Int = -1) -> Int {
  if max_items == 0 {
    return 0
  }
  let limit = if max_items < 0 { self.pending_count() } else { max_items }
  for drained = 0; drained < limit; {
    match self.queue.pop() {
      None => break drained
      Some(rec) => {
        self.sink.write(rec)
        continue drained + 1
      }
    }
  } nobreak {
    limit
  }
}

pub fn[S : Sink] QueuedSink::flush(self : QueuedSink[S]) -> Int {
  self.drain()
}

pub impl[S] Sink for QueuedSink[S] with write(self, rec) {
  let full = self.max_pending > 0 && self.pending_count() >= self.max_pending
  if !full {
    self.queue.push(rec)
  } else {
    self.dropped_count.val += 1
    match self.overflow {
      QueueOverflowPolicy::DropNewest => ()
      QueueOverflowPolicy::DropOldest => {
        ignore(self.queue.pop())
        self.queue.push(rec)
      }
    }
  }
}

pub struct FilterSink[S] {
  sink : S
  predicate : (Record) -> Bool
}

pub fn[S] filter_sink(sink : S, predicate : (Record) -> Bool) -> FilterSink[S] {
  { sink, predicate }
}

pub impl[S : Sink] Sink for FilterSink[S] with write(self, rec) {
  if (self.predicate)(rec) {
    self.sink.write(rec)
  }
}

pub struct PatchSink[S] {
  sink : S
  patch : RecordPatch
}

pub fn[S] patch_sink(sink : S, patch : RecordPatch) -> PatchSink[S] {
  { sink, patch }
}

pub impl[S : Sink] Sink for PatchSink[S] with write(self, rec) {
  self.sink.write((self.patch)(rec))
}
