///|
fn pbt_level(seed : Int) -> Level {
  match (seed & 0x3fffffff) % 5 {
    0 => Level::Trace
    1 => Level::Debug
    2 => Level::Info
    3 => Level::Warn
    _ => Level::Error
  }
}

///|
fn pbt_nonnegative(seed : Int, modulus : Int) -> Int {
  (seed & 0x3fffffff) % modulus
}

///|
fn pbt_bit(seed : Int, bit : Int) -> Bool {
  (seed & bit) != 0
}

///|
fn pbt_fields_equal(left : Array[Field], right : Array[Field]) -> Bool {
  guard left.length() == right.length() else { return false }
  for i in 0..<left.length() {
    guard left[i].key == right[i].key && left[i].value == right[i].value else {
      return false
    }
  }
  true
}

///|
fn pbt_records_equal(left : Record, right : Record) -> Bool {
  left.level.label() == right.level.label() &&
  left.timestamp_ms == right.timestamp_ms &&
  left.target == right.target &&
  left.message == right.message &&
  pbt_fields_equal(left.fields, right.fields)
}

///|
fn pbt_history_matches(
  sink : HistorySink,
  expected : Array[(String, String)],
  expected_dropped : Int,
) -> Bool {
  guard sink.count() == expected.length() else { return false }
  guard sink.dropped_count() == expected_dropped else { return false }
  let snapshot = sink.snapshot()
  guard snapshot.length() == expected.length() else { return false }
  for i in 0..<expected.length() {
    let (message, id) = expected[i]
    let record = snapshot[i]
    guard record.message == message else { return false }
    guard record.fields.length() == 1 else { return false }
    guard record.fields[0].key == "id" else { return false }
    guard record.fields[0].value == id else { return false }
  }
  // The public snapshot must not expose the sink's retained field arrays.
  if snapshot.length() > 0 {
    snapshot[0].fields.push(field("mutated", "outside"))
    guard sink.snapshot()[0].fields.length() == 1 else { return false }
  }
  true
}

///|
test "quickcheck: history sink agrees with a bounded model" {
  @quickcheck.check(
    (input : (Int, Array[(Int, Int)])) => {
      let (capacity_seed, operations) = input
      let requested_capacity = capacity_seed % 8
      let capacity = if requested_capacity <= 0 {
        1
      } else {
        requested_capacity
      }
      let sink = history_sink(capacity=requested_capacity)
      let mut expected : Array[(String, String)] = []
      let mut expected_dropped = 0
      for operation in operations {
        let (kind, value) = operation
        if (kind & 7) == 0 {
          sink.clear()
          expected = []
          expected_dropped = 0
        } else {
          let id = value.to_string()
          let message = "message:" + id
          let record = Record::new(Level::Info, message, fields=[
            field("id", id),
          ])
          @sink_graph.Sink::write(sink, record)
          if expected.length() >= capacity {
            ignore(expected.remove(0))
            expected_dropped += 1
          }
          expected.push((message, id))
        }
        guard pbt_history_matches(sink, expected, expected_dropped) else {
          return false
        }
      }
      pbt_history_matches(sink, expected, expected_dropped)
    },
    count=220,
    max_size=80,
    max_shrinks=200,
    seed=0x51A7UL,
  )
}

///|
fn pbt_queue_limit(seed : Int) -> Int {
  match seed & 3 {
    0 => -1
    1 => 0
    2 => 1
    _ => 3
  }
}

///|
fn pbt_drain_model(
  expected : Array[String],
  delivered : Array[String],
  max_items : Int,
) -> Int {
  if max_items == 0 {
    return 0
  }
  let limit = if max_items < 0 { expected.length() } else { max_items }
  let count = if limit > expected.length() { expected.length() } else { limit }
  for _ in 0..<count {
    delivered.push(expected.remove(0))
  }
  count
}

///|
fn pbt_queue_matches(
  sink : QueuedSink[CallbackSink],
  expected : Array[String],
  expected_dropped : Int,
  delivered : Ref[Array[String]],
  expected_delivered : Array[String],
) -> Bool {
  sink.pending_count() == expected.length() &&
  sink.dropped_count() == expected_dropped &&
  delivered.val == expected_delivered
}

///|
test "quickcheck: queued sink agrees with an overflow and drain model" {
  @quickcheck.check(
    (input : (Int, Int, Array[(Int, Int)])) => {
      let (max_pending_seed, policy_seed, operations) = input
      let max_pending = pbt_nonnegative(max_pending_seed, 8)
      let policy = if pbt_bit(policy_seed, 1) {
        QueueOverflowPolicy::DropOldest
      } else {
        QueueOverflowPolicy::DropNewest
      }
      let delivered : Ref[Array[String]] = Ref([])
      let sink = queued_sink(
        callback_sink(fn(record) { delivered.val.push(record.message) }),
        max_pending~,
        overflow=policy,
      )
      let expected : Array[String] = []
      let expected_delivered : Array[String] = []
      let mut expected_dropped = 0
      for operation in operations {
        let (kind, value) = operation
        match kind & 7 {
          0 | 1 | 2 | 3 => {
            let message = "message:" + value.to_string()
            let record = Record::new(Level::Info, message)
            let full = max_pending > 0 && expected.length() >= max_pending
            if full {
              expected_dropped += 1
              match policy {
                QueueOverflowPolicy::DropNewest => ()
                QueueOverflowPolicy::DropOldest => {
                  ignore(expected.remove(0))
                  expected.push(message)
                }
              }
            } else {
              expected.push(message)
            }
            @sink_graph.Sink::write(sink, record)
          }
          4 => {
            let limit = pbt_queue_limit(value)
            let expected_count = pbt_drain_model(
              expected, expected_delivered, limit,
            )
            let actual_count = sink.drain(max_items=limit)
            guard actual_count == expected_count else { return false }
          }
          5 => {
            let expected_count = pbt_drain_model(
              expected, expected_delivered, -1,
            )
            guard sink.flush() == expected_count else { return false }
          }
          _ => {
            let expected_count = pbt_drain_model(
              expected, expected_delivered, 0,
            )
            guard expected_count == 0 else { return false }
            guard sink.drain(max_items=0) == 0 else { return false }
          }
        }
        guard pbt_queue_matches(
          sink, expected, expected_dropped, delivered, expected_delivered,
        ) else {
          return false
        }
      }
      pbt_queue_matches(
        sink, expected, expected_dropped, delivered, expected_delivered,
      )
    },
    count=220,
    max_size=80,
    max_shrinks=200,
    seed=0xA11CEUL,
  )
}

///|
fn pbt_patch_for(operation : (Int, String)) -> RecordPatch {
  let (kind, value) = operation
  match kind & 7 {
    0 => identity_patch()
    1 => set_target("target." + value)
    2 => prefix_message("[" + value + "] ")
    3 => append_fields([field("extra", value)])
    4 => redact_field("secret", placeholder=value)
    _ => redact_fields(["secret", "token"], placeholder=value)
  }
}

///|
test "quickcheck: composed patches match sequential application" {
  @quickcheck.check(
    (input : (Array[(Int, String)], (Int, String, Array[(String, String)]))) => {
      let (operations, record_input) = input
      let (level_seed, message, raw_fields) = record_input
      let base = Record::new(
        pbt_level(level_seed),
        message,
        timestamp_ms=123UL,
        target="service",
        fields=raw_fields.map(entry => field(entry.0, entry.1)),
      )
      let patches : Array[RecordPatch] = operations.map(pbt_patch_for)
      let mut sequential = base
      for patch in patches {
        sequential = patch(sequential)
      }
      let composed = compose_patches(patches)(base)
      pbt_records_equal(sequential, composed)
    },
    count=220,
    max_size=70,
    max_shrinks=200,
    seed=0xC0DEUL,
  )
}

///|
fn pbt_color_mode(seed : Int) -> ColorMode {
  match pbt_nonnegative(seed, 3) {
    0 => ColorMode::Never
    1 => ColorMode::Auto
    _ => ColorMode::Always
  }
}

///|
fn pbt_color_support(seed : Int) -> ColorSupport {
  if pbt_bit(seed, 1) {
    ColorSupport::Basic
  } else {
    ColorSupport::TrueColor
  }
}

///|
fn pbt_markup_mode(seed : Int) -> StyleMarkupMode {
  match pbt_nonnegative(seed, 3) {
    0 => StyleMarkupMode::Disabled
    1 => StyleMarkupMode::Builtin
    _ => StyleMarkupMode::Full
  }
}

///|
fn pbt_sink_kind(seed : Int) -> SinkKind {
  match pbt_nonnegative(seed, 4) {
    0 => SinkKind::Console
    1 => SinkKind::JsonConsole
    2 => SinkKind::TextConsole
    _ => SinkKind::File
  }
}

///|
test "quickcheck: serialized logger configs parse to the same canonical text" {
  @quickcheck.check(
    (input : (Int, String, Bool, (Int, Int, Int, String))) => {
      let (seed, target, timestamp, sink_input) = input
      let (sink_seed, queue_seed, flags, suffix) = sink_input
      let kind = pbt_sink_kind(sink_seed)
      let path = match kind {
        SinkKind::File =>
          if suffix == "" {
            "logs/generated.log"
          } else {
            "logs/" + suffix
          }
        _ => suffix
      }
      let style_tags : Map[String, TextStyle] = if pbt_bit(flags, 16) {
        { "accent": text_style(fg=Some(suffix), bold=pbt_bit(flags, 32)) }
      } else {
        Map([])
      }
      let formatter = TextFormatterConfig::new(
        show_timestamp=pbt_bit(flags, 1),
        show_level=pbt_bit(flags, 2),
        show_target=pbt_bit(flags, 4),
        show_fields=pbt_bit(flags, 8),
        separator=if suffix == "" { " " } else { suffix },
        field_separator=if target == "" { "," } else { target },
        template="[{level}] {target} {message}",
        color_mode=pbt_color_mode(seed),
        color_support=pbt_color_support(sink_seed),
        style_markup=pbt_markup_mode(flags),
        target_style_markup=pbt_markup_mode(seed),
        fields_style_markup=pbt_markup_mode(queue_seed),
        style_tags~,
      )
      let rotation = if pbt_bit(sink_seed, 1) {
        Some(
          file_rotation(
            1 + pbt_nonnegative(queue_seed, 64),
            max_backups=1 + pbt_nonnegative(flags, 4),
          ),
        )
      } else {
        None
      }
      let sink = SinkConfig::new(
        kind~,
        path~,
        append=pbt_bit(flags, 1),
        auto_flush=pbt_bit(flags, 2),
        rotation~,
        text_formatter=formatter,
      )
      let queue = if pbt_bit(queue_seed, 1) {
        Some(
          QueueConfig::new(
            queue_seed % 17,
            overflow=if pbt_bit(queue_seed, 2) {
              QueueOverflowPolicy::DropOldest
            } else {
              QueueOverflowPolicy::DropNewest
            },
          ),
        )
      } else {
        None
      }
      let config = LoggerConfig::new(
        min_level=pbt_level(seed),
        target~,
        timestamp~,
        sink~,
        queue~,
      )
      let serialized = stringify_logger_config(config)
      (fn() -> Bool raise ConfigError {
        let parsed = parse_logger_config_text(serialized)
        stringify_logger_config(parsed) == serialized
      })() catch {
        _ => false
      }
    },
    count=180,
    max_size=60,
    max_shrinks=200,
    seed=0xBEEF1234UL,
  )
}
