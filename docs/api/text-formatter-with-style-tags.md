---
name: text-formatter-with-style-tags
group: api
category: formatter
update-time: 20260613
description: Return a TextFormatter with a specific local StyleTagRegistry attached.
key-word:
    - formatter
    - style
    - registry
    - public
---

## Text-formatter-with-style-tags

Return a copy of a `TextFormatter` with a specific local `StyleTagRegistry` attached. This method is the direct way to make one formatter use custom or overridden tag definitions without changing shared global registry state.

### Interface

```moonbit
pub fn TextFormatter::with_style_tags(self : TextFormatter, style_tags : StyleTagRegistry) -> TextFormatter {
```

#### input

- `self : TextFormatter` - Base formatter to copy.
- `style_tags : StyleTagRegistry` - Local registry to attach to the returned formatter.

#### output

- `TextFormatter` - A new formatter value whose `style_tags` field is set to `Some(style_tags)`.

### Explanation

Detailed rules explaining key parameters and behaviors

- This method only changes the formatter's local `style_tags` attachment.
- The returned formatter preserves timestamp, level, target, field, template, color, and markup settings from `self`.
- Local style tags take precedence over global registry lookup, which in turn takes precedence over builtin tags.
- The original formatter value is not mutated.

### How to Use

Here are some specific examples provided.

#### When Need Custom Tags For One Formatter Only

When one formatter should understand project-specific tag names without touching global state:
```moonbit
let tags = style_tag_registry().set_tag("accent", fg=Some("#4cc9f0"), bold=true)
let formatter = text_formatter(color_mode=ColorMode::Always).with_style_tags(tags)
```

In this example, the custom registry only affects the returned formatter value.

#### When Need To Override A Built-in Tag Locally

When a formatter should keep the standard tag vocabulary but change one entry:
```moonbit
let tags = default_style_tag_registry().set_tag("success", fg=Some("#22cc88"), underline=true)
let formatter = text_formatter(color_mode=ColorMode::Always).with_style_tags(tags)
```

In this example, the local registry shadows the built-in or global `success` definition for that formatter.

### Error Case

e.g.:
- If the relevant markup scopes are disabled, attaching local tags does not produce a visible effect.

- If callers actually want to change shared process-wide tag resolution, `set_global_style_tag_registry(...)` is the better API.

### Notes

1. This is the local, formatter-scoped alternative to editing the global style tag registry.

2. It is the natural companion to `style_tag_registry()` and `default_style_tag_registry()`.
