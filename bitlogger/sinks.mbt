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
  println(format_record(rec))
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
  println(format_record_json(rec))
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

pub struct CallbackSink {
  callback : (Record) -> Unit
}

pub fn callback_sink(callback : (Record) -> Unit) -> CallbackSink {
  { callback, }
}

pub impl Sink for CallbackSink with write(self, rec) {
  (self.callback)(rec)
}
