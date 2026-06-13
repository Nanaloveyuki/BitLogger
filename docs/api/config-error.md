---
name: config-error
group: api
category: config
update-time: 20260613
description: Public config parsing error alias used by synchronous config-loading helpers.
key-word:
    - config
    - error
    - alias
    - public
---

## Config-error

`ConfigError` is the public error type raised by synchronous config parsing helpers. It is a direct alias to the internal config error definition and currently exposes a single structured error case for invalid input.

### Interface

```moonbit
pub type ConfigError = @utils.ConfigError
```

#### output

- `ConfigError` - Public config parsing error type with the case `InvalidConfig(String)`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This is a type alias, not a separate public wrapper.
- The current public error case is `ConfigError::InvalidConfig(message)`.
- The alias is used by parsing helpers such as `parse_logger_config_text(...)` and by lower-level config parsing routines beneath it.
- Error messages describe concrete schema problems such as invalid JSON, wrong value types, unsupported enum text, or missing required values for a chosen sink kind.

### How to Use

Here are some specific examples provided.

#### When Need To Catch Config Parse Failures

When raw config text should be validated before boot:
```moonbit
let config = parse_logger_config_text(raw) catch {
  err if err is ConfigError => {
    println(err.to_string())
    return
  }
}
```

In this example, the caller keeps config validation failures separate from normal runtime work.

#### When Need To Surface A Clear Parse Message

When tooling should report why config input was rejected:
```moonbit
ignore(parse_logger_config_text("{bad json}")) catch {
  err => println(err.to_string())
}
```

In this example, the error carries a concrete message instead of failing silently.

### Error Case

e.g.:
- Invalid JSON input raises `ConfigError::InvalidConfig(...)`.

- Wrong field types, unsupported level text, unsupported sink kinds, or an empty `path` for a file sink also raise `ConfigError::InvalidConfig(...)`.

### Notes

1. This alias currently belongs to the synchronous config-loading path in `bitlogger`.

2. Async config parsers in `bitlogger_async` currently raise the generic failure surface used by that package instead of `ConfigError`.
