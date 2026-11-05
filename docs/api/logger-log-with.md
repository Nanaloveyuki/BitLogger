---
name: logger-log-with
group: api
category: logging
update-time: 20261103
description: Emit a structured record through a caller-supplied writer and preserve its typed result.
key-word:
    - logger
    - log_with
    - sync
    - public
---

## Logger-log-with

Write through an application-supplied fallible output while retaining the logger's level gate and record construction. Available since package `0.10.0`.

### Interface

```moonbit
pub fn[S, E] Logger::log_with(
  self : Logger[S],
  level : Level,
  message : String,
  write : (S, Record) -> Result[Unit, E],
  fields~ : Array[Field] = [],
  target~ : String = "",
) -> Result[Unit, E]
```

### Parameters and result

- `self` stores the sink `S`, minimum level, default target, and timestamp setting. `S` does not need to implement `Sink`.
- `level`, `message`, and `fields` form the record passed to `write`.
- `write` receives the stored sink and the constructed record once for an enabled level. Its success or typed error is returned unchanged.
- `target` overrides the default target for this call when non-empty; an empty value uses the stored default.
- A disabled level returns `Ok(())` without creating a record, capturing a timestamp, or invoking `write`.

### Behavior

When timestamping is enabled, the record contains the current timestamp. Otherwise its timestamp is zero. The method is synchronous and does not raise errors: the callback represents failure as `Err(E)`. An adapter whose API raises can catch inside the callback and return the original error as a value.

The callback owns output dispatch. `log_with` does not call `Sink::write`, traverse context/filter/patch/fanout/queue wrappers, retry, or flush automatically. If the stored sink is a wrapper, supply a writer that implements that wrapper's behavior. Existing `Logger::log` and the non-raising `Sink` trait are unchanged.

### Example

```moonbit
let logger = @log.Logger::new("android", target="Index")
let result : Result[Unit, String] = logger.log_with(
  @log.Level::Info,
  "Index built",
  (destination, record) => {
    if destination == "android" {
      Err("output unavailable: " + record.target)
    } else {
      Ok(())
    }
  },
  fields=[@log.field("resource_count", "12")],
)
match result {
  Ok(_) => ()
  Err(message) => println(message)
}
```

Import `Nanaloveyuki/BitLogger/src` as `@log`. The application decides recovery, reporting, or propagation at the result boundary.
