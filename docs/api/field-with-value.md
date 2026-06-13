---
name: field-with-value
group: api
category: record
update-time: 20260613
description: Return a copy of a field with a replaced value while preserving the key.
key-word:
    - field
    - value
    - transform
    - public
---

## Field-with-value

Return a copy of a `Field` with a different `value`. This helper is the narrowest way to rewrite one field value while preserving the existing key.

### Interface

```moonbit
pub fn Field::with_value(self : Field, value : String) -> Field {}
```

#### input

- `self : Field` - Base field whose value should be replaced.
- `value : String` - New value text for the returned field.

#### output

- `Field` - New field value carrying the updated value.

### Explanation

Detailed rules explaining key parameters and behaviors

- This helper returns a new field value instead of mutating the original one.
- Only the `value` part is replaced.
- The original `key` is preserved exactly.
- This is useful for redaction, normalization, or tests that need one adjusted field value without rebuilding the key manually.

### How to Use

Here are some specific examples provided.

#### When Need To Redact One Existing Field Value

When the field key should stay the same but the value should be hidden:
```moonbit
let user = field("user", "alice")
let redacted = user.with_value("***")
```

In this example, the returned field keeps the same key while changing only the visible value.

#### When Need To Rewrite A Field In Test Data

When one field should be adapted without reconstructing the key by hand:
```moonbit
let region = field("region", "cn").with_value("eu")
```

In this example, the helper keeps the transformation local to one field value.

### Error Case

e.g.:
- If `value` is empty, the returned field is still valid and simply carries an empty string value.

- If the key should also change, constructing a new field with `field(...)` is clearer than chaining this helper.

### Notes

1. Use this helper when the key should stay stable and only the value should change.

2. It is especially useful for redaction-style value updates in tests or adapters.
