---
name: record
group: api
category: record
update-time: 20260613
description: Public record alias used across formatting, filtering, sinks, and logger output paths.
key-word:
    - record
    - alias
    - logging
    - public
---

## Record

`Record` is the public log-event data type used throughout BitLogger. It is a direct alias to the core record model, so formatters, predicates, sinks, patches, and callback-based integrations all share the same structured event shape.

### Interface

```moonbit
pub type Record = @core.Record
```

#### output

- `Record` - Public structured log-event value containing `level`, `timestamp_ms`, `target`, `message`, and `fields`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a wrapper or a runtime logger handle.
- The current record fields are `level : Level`, `timestamp_ms : UInt64`, `target : String`, `message : String`, and `fields : Array[Field]`.
- `Record` is the common value passed through `Logger`, `AsyncLogger`, sink callbacks, formatters, predicates, and patch helpers.
- Direct construction usually starts with `Record::new(...)`, while logger write APIs create records for you during normal logging.

### How to Use

Here are some specific examples provided.

#### When Need A Shared Event Shape For Low-level Integrations

When custom formatter or sink code should work with the same event model as the logger runtime:
```moonbit
let callback = fn(rec : Record) {
  println(format_json(rec))
}
```

In this example, the alias makes it explicit that the callback receives the public record type used everywhere else in the API.

#### When Need To Inspect Record Data Directly

When filters, tests, or adapters should read event fields without going through string output:
```moonbit
let rec = Record::new(Level::Info, "started", target="svc")
println(rec.target)
```

In this example, the caller reads the structured event data directly instead of reparsing formatted output.

### Error Case

e.g.:
- `Record` itself does not have a runtime failure mode.

- Empty `target` or empty `fields` are valid and are represented directly in the record value.

### Notes

1. Use `Record::new(...)` when a record should be created explicitly outside normal logger write APIs.

2. This alias is the shared event contract for sync logging, async logging, filtering, patching, and formatting.
