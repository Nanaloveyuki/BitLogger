<html>
    <div style="display: flex; justify-content: center; align-items: center; height: 15vh;">
        <h3 title="https://moonbitlang.github.io/OSC2026/index.html#top">2026 MoonBit 国产基础软件生态开源大赛参赛作品</h3>
    </div>
    <div style="display: flex; justify-content: center; align-items: center; height: 8vh;">
        <a href="https://mooncakes.io/docs/Nanaloveyuki/BitLogger" title="点击前往 Mooncake 页面"><b>Mooncake@Nanaloveyuki/BitLogger</b></a>
    </div>
    <div style="display: flex; justify-content: center; align-items: center; height: 2vh;">
        <b>中文 | <a href="./docs/README-en.md">English</a></b>
    </div>
</html>

## 📖 介绍

BitLogger 是一个基于 MoonBit 编写的结构化日志库。

## ❇️ 特点

- 🧩 核心能力清晰：先把 logging core 做稳，再继续扩展 `FileSink`、buffered/async 等能力。
- 🏗️ 结构明确：按 `level / record / formatter / sinks / logger / global` 拆文件，便于继续维护。
- 🔌 可扩展：支持 `fanout_sink(...)` 和 `callback_sink(...)`，方便后续桥接文件、指标或外部系统。
- 📦 面向 MoonBit：API 和工程结构围绕 MoonBit 的 package / visibility / toolchain 现实约束设计。

## 🚀 快速开始

```moonbit
let logger = Logger::new(console_sink(), min_level=Level::Info, target="demo")
  .with_timestamp()
  .with_context_fields([field("service", "bitlogger")])

logger.info("starting", fields=[field("port", "8080")])
```

层级 target 示例：

```moonbit
let worker = Logger::new(console_sink(), target="app").child("worker")
worker.info("job ready")
```

自定义 callback sink 示例：

```moonbit
let hook = Logger::new(
  callback_sink(fn(rec) {
    println("callback saw [\{rec.target}] \{rec.message}")
  }),
  target="hook",
)

hook.info("hello")
```

## 📂 仓库结构

- `bitlogger/`：MoonBit 库 package，本体实现、测试与 Mooncake README
- `examples/basic/`：最小可运行示例

## 🔗 相关文档

- [Mooncake 文档页](https://mooncakes.io/docs/Nanaloveyuki/BitLogger)
- [English README](./docs/README-en.md)

