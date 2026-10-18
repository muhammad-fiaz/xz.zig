# Contributing to xz.zig

Thank you for your interest in contributing to `xz.zig`! We welcome bug reports, documentation improvements, optimization ideas, and pull requests.

## Code of Conduct

Please be respectful and constructive in all issues, pull requests, and discussions, following the [Code of Conduct](CODE_OF_CONDUCT.md).

## Tooling & Prerequisites

### Mandatory Tooling
- **Zig 0.17.0**: Required compiler toolchain. Download from [ziglang.org/download](https://ziglang.org/download/).
- **`lzma2.zig`**: Co-located at `..` (sibling directory) as the LZMA2 chunk codec provider.

### Optional Development Tooling
- **Bun** (or Node.js): Required only for building the VitePress documentation site locally (`docs/`).
- **XZ Utils (`xz`) & 7-Zip (`7z`)**: Optional CLI tools for development-time differential testing and external oracle verification. Neither is required to build or test the native container library.
- **QEMU**: Optional emulator (`qemu-arm`, `qemu-aarch64`, `qemu-riscv32`) for running non-native cross-compiled test suites locally.

## Development Workflow

Run the standard validation workflows before submitting changes:

```bash
# 1. Format all Zig source files
zig fmt src/ examples/ build.zig build.zig.zon

# 2. Check formatting without modifying files
zig fmt --check src/ examples/ build.zig build.zig.zon

# 3. Build the static library and check compilation
zig build
zig build check

# 4. Run all unit and integration tests
zig build test --summary all

# 5. Run fuzz testing and edge-case validation
zig build fuzz

# 6. Run all standalone examples
zig build run-all-examples

# 7. Run an individual example
zig build run-basic_compression
zig build run-caller_buffer
zig build run-streaming_pipeline
zig build run-checksum_types
zig build run-filter_chains
zig build run-error_handling

# 8. Build the VitePress documentation site (optional)
cd docs
bun install
bun run build
cd ..
```

## Adding Regression Tests

When fixing a bug or adding container features:
1. Add a targeted test case in the relevant module:
   - For XZ container stream encoding/decoding: [`src/xz.zig`](src/xz.zig)
   - For block header and filter pipelines: [`src/format/block_header.zig`](src/format/block_header.zig)
   - For checksum implementations: [`src/checksum/`](src/checksum/)
   - For index parsing and backward size checks: [`src/format/index.zig`](src/format/index.zig)
2. Include both valid container round-trip tests and malformed/truncated input tests to ensure graceful error return.
3. Verify that tests pass across both `Debug` and `ReleaseSafe` optimization modes.

## Coding Conventions

1. **Native Zig & Zero External Runtime Dependencies**: Pure native Zig. Do not introduce `@cImport`, link libc, or duplicate codec logic already provided by `lzma2.zig`.
2. **Container vs. Codec Separation**: Keep XZ container functionality in `xz.zig` and consume `lzma2.zig` through its public API. Do not duplicate LZMA2 match finding or range coding in `xz.zig`.
3. **Memory Safety & Allocator Ownership**: Functions that allocate must accept an explicit `std.mem.Allocator`. Caller-buffer zero-allocation APIs (`compressInto` / `decompressInto`) must be provided alongside allocating ones.
4. **No Decorative Comment Blocks**: Do not use separator lines of repeated `=======` or `-------` in comments. Use normal descriptive doc comments (`///`) on public symbols and concise technical comments for internal algorithms.
5. **Documentation Accuracy**: Every change to public API signatures or options must be updated in `docs/` and verified with `bun run build`.

## Reporting Vulnerabilities

Do not report security vulnerabilities via public GitHub issues. Follow the private reporting process detailed in [SECURITY.md](SECURITY.md).
