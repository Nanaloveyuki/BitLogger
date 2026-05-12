---
name: record-new
group: api
category: record
update-time: 20260512
description: Construct a log record explicitly from level, message, timestamp, target, and fields.
key-word:
    - record
    - constructor
    - logging
    - public
---

## Record-new

Construct a `Record` explicitly from its core fields. This is the low-level record constructor used beneath the logger APIs and is useful when records need to be created directly for formatting, filtering, sink callbacks, or tests.

### Interface

```moonbit
pub fn Record::new(
  level : Level,
  message : String,
  timestamp_ms~ : UInt64 = 0UL,
  target~ : String = "",
  fields~ : Array[Field] = [],
) -> Record {}
```

#### input

- `level : Level` - Severity level stored in the record.
- `message : String` - Log message text.
- `timestamp_ms : UInt64` - Timestamp in milliseconds, or `0UL` when omitted.
- `target : String` - Target label for the record.
- `fields : Array[Field]` - Structured field list attached to the record.

#### output

- `Record` - Structured log record value.

### Explanation

Detailed rules explaining key parameters and behaviors

- The constructor stores the provided values directly without extra processing.
- `timestamp_ms` defaults to `0UL`, which is the same no-timestamp convention used by loggers when timestamping is disabled.
- `target` and `fields` are optional and may be left empty.
- This API is useful when records need to be created outside the normal `Logger::log(...)` flow.

### How to Use

Here are some specific examples provided.

#### When Create A Record For Formatter Tests

When a formatting path should be exercised directly:
```moonbit
let rec = Record::new(
  Level::Info,
  "service started",
  target="app",
  fields=[field("region", "cn")],
)
```

In this example, the record can be passed straight to `format_text(...)` or `format_json(...)`.

#### When Feed A Callback Or Predicate Manually

When tests or adapters work with records directly:
```moonbit
let rec = Record::new(Level::Warn, "retry scheduled")
let keep = level_at_least(Level::Info)(rec)
```

In this example, the record exists independently of any logger instance.

### Error Case

e.g.:
- If `target` is empty, the record remains valid and simply carries no target label.

- If `fields` is empty, the record still works normally with formatters, sinks, and predicates.

### Notes

1. Prefer logger write APIs for normal application logging; use `Record::new(...)` when direct record construction is specifically needed.

2. This constructor is especially useful in tests and low-level integrations.

