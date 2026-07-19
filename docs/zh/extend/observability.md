# Trace Context

BitLogger 通过结构化字段承载 trace 上下文，不负责 HTTP 传播或遥测传输。应用应继续使用已选定的 tracing 库提取请求上下文，再把标识绑定到 logger。

```moonbit
let request_logger = logger.with_trace_context(
  @log.trace_context(trace_id, span_id, trace_flags="01"),
)
```

派生 logger 的每条记录都会带有 `trace_id`、`span_id`、`trace_flags`，以及传入时的 `trace_state`。原 logger 不会被修改，避免请求上下文泄漏到无关任务。

`context.as_fields()` 可用于自定义 facade。`traceparent` 解析、span 创建、采样与 OTLP 导出仍由应用选用的 tracing 实现负责。
