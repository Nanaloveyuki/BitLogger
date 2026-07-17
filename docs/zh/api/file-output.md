# 文件输出 API

文件输出是 native 能力。先检查能力，再创建文件配置，最后在有序退出时 flush 并关闭。

## `native_files_supported()`

```moonbit
pub fn native_files_supported() -> Bool
```

native 后端当前返回 `true`，非文件能力后端返回 `false`。这是运行时能力检查，不保证后续文件操作一定成功，路径、权限和文件系统状态仍可能导致失败。

## `file(...)` 与 `with_file_rotation(...)`

```moonbit
pub fn file(
  path : String,
  min_level~ : Level = Level::Info,
  target~ : String = "",
  timestamp~ : Bool = false,
  append~ : Bool = true,
  auto_flush~ : Bool = true,
  rotation~ : FileRotation? = None,
  text_formatter~ : TextFormatterConfig = default_text_formatter_config(),
) -> LoggerConfig raise ConfigError

pub fn with_file_rotation(
  config : LoggerConfig,
  max_bytes : Int,
  max_backups~ : Int = 1,
) -> LoggerConfig
```

`file(...)` 要求非空路径。`with_file_rotation(...)` 只对 file config 生效；输入不是文件 sink 时原样返回。`max_bytes` 是活动文件上限，`max_backups` 是保留的轮转备份数。

## `file_close()`

```moonbit
pub fn ConfiguredLogger::file_close(self : ConfiguredLogger) -> Bool
```

关闭 config 构建的文件 sink。队列文件 sink 会依次 drain、flush、close；只有整条路径成功且期间没有新的写入、flush 或轮转失败时才返回 `true`。非文件 sink 返回 `false`。

## 英文原始 API

- [`native_files_supported()`](../../api/native-files-supported.md)
- [`file(...)`](../../api/file.md)
- [`with_file_rotation(...)`](../../api/with-file-rotation.md)
- [`file_close()`](../../api/configured-logger-file-close.md)
