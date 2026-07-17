# Extend A Logger

Start from an [Example flow](../examples/index.md), then add one extension at a time. These pages explain when an abstraction is useful and which operational boundary it introduces.

## Extension Map

| Need | Extension | Main trade-off |
| --- | --- | --- |
| Absorb short output bursts | [Queueing](./queue.md) | You must choose overflow and flush behavior. |
| Send records to multiple destinations or route by level | [Sink composition](./composition.md) | More explicit construction than presets. |
| Control terminal appearance | [Text formatting](./formatting.md) | Formatting affects presentation, not record structure. |
| Share code across native and web targets | [Target boundaries](./targets.md) | File and async runtime behavior differ by backend. |

For exact function signatures, follow each page's links into the [API reference](../api/index.md).
