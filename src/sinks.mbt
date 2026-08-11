///|
pub using @sink_graph {trait Sink}

///|
pub type ConsoleSink = @sink_graph.ConsoleSink

///|
pub fn console_sink() -> ConsoleSink {
  @sink_graph.console_sink()
}

///|
pub type ContextSink[S] = @sink_graph.ContextSink[S]

///|
pub fn[S] context_sink(
  sink : S,
  context_fields : Array[Field],
) -> ContextSink[S] {
  @sink_graph.context_sink(sink, context_fields)
}

///|
pub type JsonConsoleSink = @sink_graph.JsonConsoleSink

///|
pub fn json_console_sink() -> JsonConsoleSink {
  @sink_graph.json_console_sink()
}

///|
pub type FormattedConsoleSink = @sink_graph.FormattedConsoleSink

///|
pub fn formatted_console_sink(
  formatter : RecordFormatter,
) -> FormattedConsoleSink {
  @sink_graph.formatted_console_sink(formatter)
}

///|
pub fn text_console_sink(formatter : TextFormatter) -> FormattedConsoleSink {
  @sink_graph.text_console_sink(formatter)
}

///|
pub type FormattedCallbackSink = @sink_graph.FormattedCallbackSink

///|
pub fn formatted_callback_sink(
  formatter : RecordFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
  @sink_graph.formatted_callback_sink(formatter, callback)
}

///|
pub fn text_callback_sink(
  formatter : TextFormatter,
  callback : (String) -> Unit,
) -> FormattedCallbackSink {
  @sink_graph.text_callback_sink(formatter, callback)
}

///|
pub type FanoutSink[A, B] = @sink_graph.FanoutSink[A, B]

///|
pub fn[A, B] fanout_sink(left : A, right : B) -> FanoutSink[A, B] {
  @sink_graph.fanout_sink(left, right)
}

///|
pub type SplitSink[A, B] = @sink_graph.SplitSink[A, B]

///|
pub fn[A, B] split_sink(
  left : A,
  right : B,
  predicate : (Record) -> Bool,
) -> SplitSink[A, B] {
  @sink_graph.split_sink(left, right, predicate)
}

///|
pub fn[A, B] split_by_level(
  left : A,
  right : B,
  min_level? : Level = Level::Warn,
) -> SplitSink[A, B] {
  @sink_graph.split_by_level(left, right, min_level~)
}

///|
pub type CallbackSink = @sink_graph.CallbackSink

///|
pub fn callback_sink(callback : (Record) -> Unit) -> CallbackSink {
  @sink_graph.callback_sink(callback)
}

///|
pub type HistorySink = @sink_graph.HistorySink

///|
pub fn history_sink(capacity? : Int = 128) -> HistorySink {
  @sink_graph.history_sink(capacity~)
}

///|
pub type BufferedSink[S] = @sink_graph.BufferedSink[S]

///|
pub fn[S] buffered_sink(sink : S, flush_limit? : Int = 1) -> BufferedSink[S] {
  @sink_graph.buffered_sink(sink, flush_limit~)
}

///|
pub type QueueOverflowPolicy = @queue_model.QueueOverflowPolicy

///|
pub type QueuedSink[S] = @sink_graph.QueuedSink[S]

///|
pub fn[S] queued_sink(
  sink : S,
  max_pending? : Int = 0,
  overflow? : QueueOverflowPolicy = QueueOverflowPolicy::DropNewest,
) -> QueuedSink[S] {
  @sink_graph.queued_sink(sink, max_pending~, overflow~)
}

///|
pub type FilterSink[S] = @sink_graph.FilterSink[S]

///|
pub fn[S] filter_sink(sink : S, predicate : (Record) -> Bool) -> FilterSink[S] {
  @sink_graph.filter_sink(sink, predicate)
}

///|
pub type PatchSink[S] = @sink_graph.PatchSink[S]

///|
pub fn[S] patch_sink(sink : S, patch : RecordPatch) -> PatchSink[S] {
  @sink_graph.patch_sink(sink, patch)
}
