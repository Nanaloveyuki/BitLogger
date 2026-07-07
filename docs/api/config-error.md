---
name: config-error
group: api
category: config
update-time: 20260707
description: Public config parsing error re-exported from config_model for synchronous config-loading helpers.
key-word:
    - config
    - error
    - alias
    - public
---

## Config-error

`ConfigError` is the public error type raised by synchronous config parsing helpers. On the root `src` facade, it is re-exported from `src/config_model`, which is the real owner of the structured config error definition.

### Interface

```moonbit
pub using @config_model { type ConfigError }
```

#### output

- `ConfigError` - Public config parsing error type with the case `InvalidConfig(String)`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This root surface is a re-export, not the concrete owner definition.
- The concrete error lives in `@config_model.ConfigError`, not in `@utils`.
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
