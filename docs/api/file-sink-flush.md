---
name: file-sink-flush
group: api
category: sink
update-time: 20260613
description: Flush a FileSink when it currently has an available file handle.
key-word:
    - file
    - sink
    - flush
    - public
---

## File-sink-flush

Flush a `FileSink` directly. This helper is the concrete file-sink flush surface when code is working with a `FileSink` value instead of a configured runtime wrapper.

### Interface

```moonbit
pub fn FileSink::flush(self : FileSink) -> Bool {
```

#### input

- `self : FileSink` - File sink to flush.

#### output

- `Bool` - Whether the flush operation succeeded.

### Explanation

Detailed rules explaining key parameters and behaviors

- If the sink currently has no file handle, the method returns `false`.
- On flush failure, `flush_failures` is incremented.
- On success, failure counters are left unchanged.
- This helper does not reopen the sink automatically.
- If another alias already closed the same underlying sink handle, this method also returns `false`.

### How to Use

Here are some specific examples provided.

#### When Need Explicit File Durability Steps

When a concrete file sink should flush buffered file output explicitly:
```moonbit
ignore(sink.flush())
```

In this example, the caller requests a direct file flush on the sink value itself.

#### When Need A Flush Success Flag

When code should branch on the outcome of a direct file flush:
```moonbit
let ok = sink.flush()
```

In this example, the result tells the caller whether the current flush succeeded.

### Error Case

e.g.:
- If the sink is unavailable, the method returns `false`.

- If repeated flush failures matter operationally, inspect `flush_failures()` or `state()` instead of ignoring the result forever.

### Notes

1. Prefer this helper when you are working with a `FileSink` directly rather than through `ConfiguredLogger`.

2. This method is narrower than automatic per-write flushing controlled by `auto_flush` policy.
