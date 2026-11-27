---
name: target-verification
group: api
category: verification
update-time: 20261127
description: Current release-facing local verification boundary for BitLogger multi-target support claims.
key-word:
    - target
    - verification
    - matrix
    - public
---

## Target-verification

The current checkout was checked on Linux x86_64 with `moonc v1.0.0-rc1+3c0520448` and `moon 0.1.20261126`.

### Verification Matrix

| Area | native | js | wasm | wasm-gc | llvm |
| --- | --- | --- | --- | --- | --- |
| `src` strict compile check | verified | verified | verified | verified | not verified |
| `src-async` strict compile check | verified | verified | verified | unsupported | unsupported |
| Complete module tests | 320 passed | 312 passed | 312 passed | 204 synchronous tests passed | not run |
| `src-async` tests | 115 passed | 108 passed | 108 passed | unsupported | unsupported |

### Runtime boundary

`src-async` and its `utils` package use `moonbitlang/core/async` on native, js, and wasm. The wasm-gc test command runs the synchronous suite.

Async file I/O is native-only. The JavaScript and wasm suites exercise async logging and the unavailable-file-backend behavior. The verification matrix records local Linux results.

### Commands Used

```sh
moon fmt --check
moon info
for target in native js wasm wasm-gc; do
  moon check --target "$target" --deny-warn
  moon test --target "$target" --deny-warn
done
for target in native js wasm; do
  moon check src-async --target "$target" --deny-warn
  moon test src-async --target "$target" --deny-warn
done
```

LLVM remains unverified for synchronous logging: the pinned stable toolchain does not ship the required LLVM prelude. It is excluded from the declared async target set.
