---
name: target-verification
group: api
category: verification
update-time: 20260521
description: Current release-facing local verification boundary for BitLogger multi-target support claims.
key-word:
    - target
    - verification
    - matrix
    - public
---

## Target-verification

This note records the current release-facing local verification boundary for BitLogger's multi-target claims. It is intentionally small: the goal is to separate design intent from what was actually re-checked in the current environment.

### Verification Matrix

| Area | native | js | wasm | wasm-gc | llvm |
| --- | --- | --- | --- | --- | --- |
| `src` compile check | verified | verified | verified | verified | not locally verified |
| `src-async` compile check | verified | verified | verified | verified | not locally verified |
| `moon test` | verified in current local environment | not separately re-run | not separately re-run | not separately re-run | not run |
| `moon test src-async` | verified | verified | not separately re-run | verified | not run |

### Explanation

Detailed rules explaining key parameters and behaviors

- `verified` here means a local verification command was re-run successfully in the current environment.
- `not locally verified` means the release should not imply fresh local confirmation even if the package is still designed for that target.
- `llvm` is currently experimental in practice for this release context and did not complete local verification in this environment.
- `src-async` now has fresh local test evidence on both `js` and `wasm-gc` in addition to the native path, so async target notes may rely on more than compile-only confirmation for those targets.
- `wasm` has been re-checked at compile time and should be distinguished from the earlier state where only `wasm-gc` and `js` had been explicitly re-confirmed.
- Example-level limitations, such as `async fn main` entry support, are separate from the library-level compile matrix above.

### Commands Used

The current local verification evidence for this note is based on commands such as:

```text
moon test
moon check --target native
moon check --target js
moon check --target wasm
moon check --target wasm-gc
moon check src-async --target native
moon check src-async --target js
moon check src-async --target wasm
moon check src-async --target wasm-gc
moon test src-async --target native
moon test src-async --target js
moon test src-async --target wasm-gc
```

### Error Case

e.g.:
- If a target is described as part of the design intent but not locally re-verified here, readers should not treat it as freshly confirmed release evidence.

- If `llvm` toolchain support changes later, this page should be updated together with the relevant verification commands rather than silently relying on old wording.

### Notes

1. This page is a release-facing verification note, not a portability promise by itself.

2. API pages that mention target-sensitive behavior should defer to this page when readers need the current verification boundary.
