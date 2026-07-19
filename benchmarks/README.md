# BitLogger Benchmarks

Run the native baseline from the repository root:

```powershell
moon bench benchmarks --target native --release --deny-warn
```

The suite measures callback emission, trace-context field binding, synchronous queue enqueue-and-flush, and native file writes. It intentionally has no pass/fail threshold: compare results only on the same machine, toolchain, target, and power profile.

Async throughput remains lifecycle-sensitive and is exercised by the native integration test rather than mixed into these synchronous microbenchmarks. Record its end-to-end measurements separately when profiling an application workload.
