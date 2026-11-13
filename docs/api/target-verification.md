---
name: target-verification
group: api
category: verification
update-time: 20261113
description: Current release-facing local verification boundary for BitLogger multi-target support claims.
key-word:
    - target
    - verification
    - matrix
    - public
---

## Target-verification

Release 1.5.2 (0.11.2) was checked on Linux x86_64 with `moonc v0.10.20+65efd5b93 (2026-11-05)` and `moon 0.1.20261104`.

### Verification Matrix

| Area | native | js | wasm | wasm-gc | llvm |
| --- | --- | --- | --- | --- | --- |
| `src` strict compile check | verified | verified | verified | verified | not verified |
| `src-async` strict compile check | verified | verified | verified | unsupported | unsupported |
| Complete module tests | 320 passed | 312 passed | 312 passed | 204 synchronous tests passed | not run |
| `src-async` tests | 115 passed | 108 passed | 108 passed | unsupported | unsupported |

### Runtime boundary

`moonbitlang/async@0.22.9` explicitly lists wasm-gc as unsupported. A standalone module containing only `async test { @async.pause() }` ran zero tests with the earlier 0.22.4 dependency on the same compiler; the old successful test command did not verify async execution on wasm-gc. With 0.22.9, linking that unsupported runtime produces an invalid Scheduler reference cast.

`src-async` and its `utils` package now declare `native+wasm+js`. The synchronous `src` packages retain wasm-gc support. `moon test --target wasm-gc` checks the synchronous suite and excludes the unsupported async packages; the default `moon test` also succeeds on the CLI's default wasm target; no supported-target async tests were removed. Native, js, and wasm continue to run their complete existing async suites.

Async file I/O is native-only. JavaScript and wasm test the compatibility and unavailable-file-backend behavior. Eight native examples and the native release build also passed. macOS and Windows results come from the CI matrix, rather than this local Linux verification.

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
