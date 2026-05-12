---
name: prefix-message
group: api
category: patching
update-time: 20260512
description: Create a reusable record patch that prepends text to the message.
key-word:
    - patch
    - message
    - transform
    - public
---

## Prefix-message

Create a `RecordPatch` that prepends a fixed prefix to `rec.message`. This helper is useful for tagging records with stable context without changing every call site.

### Interface

```moonbit
pub fn prefix_message(prefix : String) -> RecordPatch {}
```

#### input

- `prefix : String` - Text inserted before the original message.

#### output

- `RecordPatch` - Patch that returns a record whose message starts with `prefix`.

### Explanation

Detailed rules explaining key parameters and behaviors

- The patch preserves the original message content after the inserted prefix.
- It does not touch target, level, timestamp, or fields.
- This helper is useful for environment tags, subsystem labels, and compatibility shims.
- When combined with other patches, composition order controls whether the prefix is applied before or after other message rewrites.

### How to Use

Here are some specific examples provided.

#### When Add A Stable Channel Marker

When console output should show one visible label:
```moonbit
let logger = Logger::new(console_sink())
  .with_patch(prefix_message("[worker] "))
```

In this example, every emitted message starts with `[worker] `.

#### When Compose With Redaction

When records need both labeling and field protection:
```moonbit
let patch = compose_patches([
  prefix_message("[safe] "),
  redact_field("token"),
])
```

In this example, message text is rewritten while fields remain independently patchable.

### Error Case

e.g.:
- If `prefix` is empty, the patch behaves like a pass-through message rewrite.

- If several patches prepend text, the final message reflects composition order.

### Notes

1. Prefer this helper over concatenating prefixes at every log call site.

2. Keep prefixes short so they do not drown out the original message text.

