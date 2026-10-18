---
layout: home
title: Native XZ Container Compression & Decompression Library for Zig
titleTemplate: ":title | xz.zig"
description: Complete, type-safe, pure native Zig 0.17.0 implementation of the XZ container file format. Full multi-block streaming, CRC32, CRC64, SHA-256 checks, Delta and BCJ filters, zero external C dependencies.
keywords: native xz compression and decompression library for zig, zig xz, pure zig xz container, 7-zip xz, liblzma zig, zig 0.17.0, zero dependencies

hero:
  name: "xz.zig"
  text: "Native XZ Container Compression for Zig"
  tagline: "Native Zig XZ container compression library."
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: Examples
      link: /examples/
    - theme: alt
      text: View on GitHub
      link: https://github.com/muhammad-fiaz/xz.zig

features:
  - icon: ⚡
    title: Pure Native Zig (0.17.0)
    details: Engineered from first principles in native Zig without `@cImport`, C compiler requirements, or external runtime dependencies.
  - icon: 🗜️
    title: Standard XZ Container Format
    details: Implements the official XZ specification with 12-byte stream headers (`FD 37 7A 58 5A 00`), 4-byte block framing, variable-length integers, indexes, and stream footers.
  - icon: 🛡️
    title: Multi-Algorithm Integrity Checks
    details: Complete native support for None, CRC32 (IEEE 802.3), CRC64 (ECMA-182 reversed polynomial), and cryptographic SHA-256 block checksums.
  - icon: 🔗
    title: Composable Filter Chains
    details: Supports primary LZMA2 (`0x21`) via the independent `lzma2.zig` package, plus native Delta (`0x03`) and x86 BCJ branch-call-jump (`0x04`) address translation filters.
  - icon: 🌊
    title: First-Class Streaming I/O
    details: Incremental block-by-block and reader/writer streaming pipelines (`compressStream`, `decompressStream`, `StreamingCompressor`) with bounded memory.
  - icon: 🔄
    title: Zero-Heap Caller Buffers
    details: Stack and caller-provided buffer APIs (`compressInto`, `decompressInto`) operate with zero dynamic heap allocation overhead.
  - icon: 🧪
    title: 100% Cross-Tool Interoperability
    details: Rigorously cross-verified with official XZ Utils (`xz.exe` v5.8.1) and 7-Zip (`7z.exe` v26.03) with 100% bit-perfect decoding parity.
---

## Installation

Add `xz.zig` to your project using `zig fetch`:

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/xz.zig.git
```

Then expose the module in your `build.zig`:

```zig
const xz_dep = b.dependency("xz", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("xz", xz_dep.module("xz"));
```

## Quick Example

Compress and decompress data in just a few lines of idiomatic Zig:

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const payload = "Native XZ container compression in pure Zig 0.17.0! High-ratio dictionary encoding with CRC64.";

    // One-shot heap compression with standard CRC64 integrity check
    const compressed = try xz.compress(allocator, payload, .{ .check = .crc64 });
    defer allocator.free(compressed);

    // One-shot heap decompression
    const restored = try xz.decompress(allocator, compressed, .{});
    defer allocator.free(restored);

    std.debug.print("Original size:   {d} bytes\n", .{payload.len});
    std.debug.print("Compressed size: {d} bytes\n", .{compressed.len});
    std.debug.print("Restored:        {s}\n", .{restored});
}
```
