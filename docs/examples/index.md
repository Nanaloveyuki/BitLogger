# Examples

Examples are the primary BitLogger learning path. Each page starts from an application concern, shows the complete minimum code, and then points to the API reference for exact contracts.

## Choose A Flow

| Need | Start here | Then extend with |
| --- | --- | --- |
| Print structured logs to a terminal | [Console and fields](./console.md) | [Text formatting](../extend/formatting.md) |
| Keep local logs with bounded disk use | [File rotation](./file-rotation.md) | [Target boundaries](../extend/targets.md) |
| Build logging from app configuration | [Configuration](./config.md) | [Queueing](../extend/queue.md) |
| Avoid blocking a native application on writes | [Async lifecycle](./async.md) | [Sink composition](../extend/composition.md) |

## Repository Examples

The runnable sources live under `examples/`. The guides below explain their intended use instead of duplicating every API detail:

- `examples/console_basic` for terminal and JSON records
- `examples/config_build` for parsed configuration
- `examples/file_rotation` for native file output
- `examples/async_basic` for the async lifecycle
- `examples/presets`, `examples/text_formatter`, and `examples/style_tags` for follow-on customization

Use the [API reference](../api/index.md) when a guide links to a symbol and you need its full signature or edge-case behavior.
