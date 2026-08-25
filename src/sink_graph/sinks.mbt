///|
type Record = @core.Record

///|
type Field = @core.Field

///|
type Level = @core.Level

///|
type RecordFormatter = @formatting.RecordFormatter

///|
type TextFormatter = @formatting.TextFormatter

///|
type RecordPatch = @record_ops.RecordPatch

///|
pub(open) trait Sink {
  fn write(Self, Record) -> Unit
  async fn write_async(Self, Record) -> Unit = _
}

///|
impl Sink with fn write_async(self : Self, rec : Record) {
  self.write(rec)
}

///|
pub struct ConsoleSink {
  _dummy : Unit
}

///|
pub fn console_sink() -> ConsoleSink {
  { _dummy: () }
}

///|
pub impl Sink for ConsoleSink with fn write(self, rec) {
  ignore(self)
  println(@formatting.format_text(rec))
}

///|
pub struct ContextSink[S] {
  sink : S
  context_fields : Array[Field]
}

///|
pub fn[S] context_sink(
  sink : S,
  context_fields : Array[Field],
) -> ContextSink[S] {
  { sink, context_fields }
}

///|
pub impl[S : Sink] Sink for ContextSink[S] with fn write(self, rec) {
  let merged = if self.context_fields.length() == 0 {
    rec.fields
  } else if rec.fields.length() == 0 {
    self.context_fields
  } else {
    self.context_fields + rec.fields
  }
  self.sink.write(rec.with_fields(merged))
}

///|
pub impl[S : Sink] Sink for ContextSink[S] with fn write_async(self, rec) {
  let merged = if self.context_fields.length() == 0 {
    rec.fields
  } else if rec.fields.length() == 0 {
    self.context_fields
  } else {
    self.context_fields + rec.fields
  }
  self.sink.write_async(rec.with_fields(merged))
}

///|
pub struct JsonConsoleSink {
  _dummy : Unit
}

///|
pub fn json_console_sink() -> JsonConsoleSink {
  { _dummy: () }
}

///|
pub impl Sink for JsonConsoleSink with fn write(self, rec) {
  ignore(self)
  println(@formatting.format_json(rec))
}

///|
pub struct FormattedConsoleSink {
  formatter : RecordFormatter
}

///|
pub fn formatted_console_sink(
  formatter : RecordFormatter,
) -> FormattedConsoleSink {
  { formatter, }
}

///|
pub fn text_console_sink(formatter : TextFormatter) -> FormattedConsoleSink {
  formatted_console_sink(fn(rec) { @formatting.format_text(rec, formatter~) })
}

///|
pub impl Sink for FormattedConsoleSink with fn write(self, rec) {
  println((self.formatter)(rec))
}

///|
pub struct FormattedCallbackSink {
  formatter : RecordFormatter
  callback : (String) -> Unit
}

///|
pub fn formatted_callback_sink(
  formatter : RecordFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
  { formatter, callback }
}

///|
pub fn text_callback_sink(
  formatter : TextFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
  formatted_callback_sink(
    fn(rec) { @formatting.format_text(rec, formatter~) },
    callback,
  )
}

///|
pub impl Sink for FormattedCallbackSink with fn write(self, rec) {
  (self.callback)((self.formatter)(rec))
}

///|
pub struct FanoutSink[A, B] {
  left : A
  right : B
}

///|
pub fn[A, B] fanout_sink(left : A, right : B) -> FanoutSink[A, B] {
  { left, right }
}

///|
pub impl[A : Sink, B : Sink] Sink for FanoutSink[A, B] with fn write(self, rec) {
  self.left.write(rec)
  self.right.write(rec.copy())
}

///|
pub impl[A : Sink, B : Sink] Sink for FanoutSink[A, B] with fn write_async(
  self,
  rec,
) {
  self.left.write_async(rec)
  self.right.write_async(rec.copy())
}

///|
pub struct SplitSink[A, B] {
  left : A
  right : B
  predicate : (Record) -> Bool
}

///|
pub fn[A, B] split_sink(
  left : A,
  right : B,
  predicate : (Record) -> Bool,
) -> SplitSink[A, B] {
  { left, right, predicate }
}

///|
pub fn[A, B] split_by_level(
  left : A,
  right : B,
  min_level? : Level = Level::Warn,
) -> SplitSink[A, B] {
  split_sink(left, right, fn(rec) { rec.level.enabled(min_level) })
}

///|
pub impl[A : Sink, B : Sink] Sink for SplitSink[A, B] with fn write(self, rec) {
  if (self.predicate)(rec) {
    self.left.write(rec)
  } else {
    self.right.write(rec)
  }
}

///|
pub impl[A : Sink, B : Sink] Sink for SplitSink[A, B] with fn write_async(
  self,
  rec,
) {
  if (self.predicate)(rec) {
    self.left.write_async(rec)
  } else {
    self.right.write_async(rec)
  }
}

///|
pub struct CallbackSink {
  callback : (Record) -> Unit
}

///|
pub fn callback_sink(callback : (Record) -> Unit) -> CallbackSink {
  { callback, }
}

///|
pub impl Sink for CallbackSink with fn write(self, rec) {
  (self.callback)(rec)
}

///|
pub struct HistorySink {
  records : Ref[Array[Record]]
  capacity : Int
  dropped_count : Ref[Int]
}

///|
pub fn history_sink(capacity? : Int = 128) -> HistorySink {
  let capacity = if capacity <= 0 { 1 } else { capacity }
  { records: Ref([]), capacity, dropped_count: Ref(0) }
}

///|
pub fn HistorySink::capacity(self : HistorySink) -> Int {
  self.capacity
}

///|
pub fn HistorySink::count(self : HistorySink) -> Int {
  self.records.val.length()
}

///|
pub fn HistorySink::dropped_count(self : HistorySink) -> Int {
  self.dropped_count.val
}

///|
fn copy_record(record : Record) -> Record {
  Record::new(
    record.level,
    record.message,
    timestamp_ms=record.timestamp_ms,
    target=record.target,
    fields=record.fields.map(field => Field::with_value(field, field.value)),
  )
}

///|
pub fn HistorySink::snapshot(self : HistorySink) -> Array[Record] {
  self.records.val.map(copy_record)
}

///|
pub fn HistorySink::clear(self : HistorySink) -> Unit {
  self.records.val = []
  self.dropped_count.val = 0
}

///|
pub impl Sink for HistorySink with fn write(self, rec) {
  let records = self.records.val
  if records.length() >= self.capacity {
    self.dropped_count.val += 1
    let retained = records[1:].to_owned()
    retained.push(copy_record(rec))
    self.records.val = retained
  } else {
    records.push(copy_record(rec))
  }
}

///|
pub struct BufferedSink[S] {
  sink : S
  buffer : Ref[Array[Record]]
  flush_limit : Int
}

///|
pub fn[S] buffered_sink(sink : S, flush_limit? : Int = 1) -> BufferedSink[S] {
  let actual_limit = if flush_limit <= 0 { 1 } else { flush_limit }
  { sink, buffer: Ref([]), flush_limit: actual_limit }
}

///|
pub fn[S] BufferedSink::pending_count(self : BufferedSink[S]) -> Int {
  self.buffer.val.length()
}

///|
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

///|
pub impl[S : Sink] Sink for BufferedSink[S] with fn write(self, rec) {
  self.buffer.val.push(rec)
  if self.buffer.val.length() >= self.flush_limit {
    self.flush()
  }
}

///|
pub async fn[S : Sink] BufferedSink::flush_async(
  self : BufferedSink[S],
) -> Unit {
  if self.buffer.val.length() == 0 {
    ()
  } else {
    let pending = self.buffer.val
    self.buffer.val = []
    for rec in pending {
      self.sink.write_async(rec)
    }
  }
}

///|
pub impl[S : Sink] Sink for BufferedSink[S] with fn write_async(self, rec) {
  self.buffer.val.push(rec)
  if self.buffer.val.length() >= self.flush_limit {
    self.flush_async()
  }
}

///|
pub type QueueOverflowPolicy = @queue_model.QueueOverflowPolicy

///|
pub struct QueuedSink[S] {
  sink : S
  queue : @queue.Queue[Record]
  max_pending : Int
  overflow : QueueOverflowPolicy
  dropped_count : Ref[Int]
}

///|
pub fn[S] queued_sink(
  sink : S,
  max_pending? : Int = 0,
  overflow? : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueuedSink[S] {
  {
    sink,
    queue: @queue.Queue([]),
    max_pending,
    overflow,
    dropped_count: Ref(0),
  }
}

///|
pub fn[S] QueuedSink::pending_count(self : QueuedSink[S]) -> Int {
  self.queue.length()
}

///|
pub fn[S] QueuedSink::dropped_count(self : QueuedSink[S]) -> Int {
  self.dropped_count.val
}

///|
pub fn[S : Sink] QueuedSink::drain(
  self : QueuedSink[S],
  max_items? : Int = -1,
) -> Int {
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

///|
pub async fn[S : Sink] QueuedSink::drain_async(
  self : QueuedSink[S],
  max_items? : Int = -1,
) -> Int {
  if max_items == 0 {
    return 0
  }
  let limit = if max_items < 0 { self.pending_count() } else { max_items }
  for drained = 0; drained < limit; {
    match self.queue.pop() {
      None => break drained
      Some(rec) => {
        self.sink.write_async(rec)
        continue drained + 1
      }
    }
  } nobreak {
    limit
  }
}

///|
pub fn[S : Sink] QueuedSink::flush(self : QueuedSink[S]) -> Int {
  self.drain()
}

///|
pub async fn[S : Sink] QueuedSink::flush_async(self : QueuedSink[S]) -> Int {
  self.drain_async()
}

///|
pub impl[S] Sink for QueuedSink[S] with fn write(self, rec) {
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

///|
pub struct FilterSink[S] {
  sink : S
  predicate : (Record) -> Bool
}

///|
pub fn[S] filter_sink(sink : S, predicate : (Record) -> Bool) -> FilterSink[S] {
  { sink, predicate }
}

///|
pub impl[S : Sink] Sink for FilterSink[S] with fn write(self, rec) {
  if (self.predicate)(rec) {
    self.sink.write(rec)
  }
}

///|
pub impl[S : Sink] Sink for FilterSink[S] with fn write_async(self, rec) {
  if (self.predicate)(rec) {
    self.sink.write_async(rec)
  }
}

///|
pub struct PatchSink[S] {
  sink : S
  patch : RecordPatch
}

///|
pub fn[S] patch_sink(sink : S, patch : RecordPatch) -> PatchSink[S] {
  { sink, patch }
}

///|
pub impl[S : Sink] Sink for PatchSink[S] with fn write(self, rec) {
  self.sink.write((self.patch)(rec))
}

///|
pub impl[S : Sink] Sink for PatchSink[S] with fn write_async(self, rec) {
  self.sink.write_async((self.patch)(rec))
}
