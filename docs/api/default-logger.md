---
name: default-logger
group: api
category: global
update-time: 20260512
description: Create the shared console-backed logger value used by the global logging helpers.
key-word:
    - global
    - logger
    - default
    - public
---

## Default-logger

Create a `Logger[ConsoleSink]` from the current shared default global configuration. This is the logger value used internally by the global helper functions such as `log(...)`, `info(...)`, and `error(...)`.

### Interface

```moonbit
pub fn default_logger() -> Logger[ConsoleSink] {}
```

#### output

- `Logger[ConsoleSink]` - Logger built from the shared console sink, current default minimum level, and current default target.

### Explanation

Detailed rules explaining key parameters and behaviors

- The returned logger is built from `default_console_sink`, `default_min_level_ref`, and `default_target_ref`.
- Each call reflects the current shared configuration at that moment.
- The logger writes to the standard console sink path.
- This helper is useful when you want the same baseline behavior as the global shortcuts but still need the explicit `Logger` object for chaining or inspection.

### How to Use

Here are some specific examples provided.

#### When Start From Global Defaults But Keep A Logger Value

When code wants the default console path with later composition:
```moonbit
let logger = default_logger().with_timestamp()
logger.info("service started")
```

In this example, the logger starts from global defaults and then gains extra instance-level behavior.

#### When Inspect Current Shared Behavior

When code should branch using the same threshold as global helpers:
```moonbit
let logger = default_logger()
if logger.is_enabled(Level::Debug) {
  logger.debug("debug path active")
}
```

In this example, the explicit logger mirrors the same level gate used by global shortcut calls.

### Error Case

e.g.:
- If the shared default target is empty, the returned logger is still valid and simply uses an empty target.

- Changes made later through `set_default_min_level(...)` or `set_default_target(...)` do not mutate an already-stored logger value.

### Notes

1. This helper returns a normal `Logger`, so further chaining is available.

2. It is the bridge between the simple global API and the explicit typed logger workflow.

