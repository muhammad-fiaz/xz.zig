<div align="center">

# xz.zig

<a href="https://muhammad-fiaz.github.io/xz.zig/"><img src="https://img.shields.io/badge/docs-muhammad--fiaz.github.io-blue" alt="Documentation"></a>
<a href="https://ziglang.org/"><img src="https://img.shields.io/badge/Zig-0.17.0%20or%20later-orange.svg?logo=zig" alt="Zig Version"></a>
<a href="https://github.com/muhammad-fiaz/xz.zig"><img src="https://img.shields.io/github/stars/muhammad-fiaz/xz.zig" alt="GitHub stars"></a>
<a href="https://github.com/muhammad-fiaz/xz.zig/issues"><img src="https://img.shields.io/github/issues/muhammad-fiaz/xz.zig" alt="GitHub issues"></a>
<a href="https://github.com/muhammad-fiaz/xz.zig/pulls"><img src="https://img.shields.io/github/issues-pr/muhammad-fiaz/xz.zig" alt="GitHub pull requests"></a>
<a href="https://github.com/muhammad-fiaz/xz.zig"><img src="https://img.shields.io/github/last-commit/muhammad-fiaz/xz.zig" alt="GitHub last commit"></a>
<a href="https://github.com/muhammad-fiaz/xz.zig/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"></a>
<a href="https://github.com/muhammad-fiaz/xz.zig/actions/workflows/ci.yml"><img src="https://github.com/muhammad-fiaz/xz.zig/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
<img src="https://img.shields.io/badge/platforms-linux%20%7C%20windows%20%7C%20macos-blue" alt="Supported Platforms">
<a href="https://github.com/muhammad-fiaz/xz.zig/releases/latest"><img src="https://img.shields.io/github/v/release/muhammad-fiaz/xz.zig?label=Latest%20Release&style=flat-square" alt="Latest Release"></a>
<a href="https://pay.muhammadfiaz.com"><img src="https://img.shields.io/badge/Sponsor-pay.muhammadfiaz.com-ff69b4?style=flat&logo=heart" alt="Sponsor"></a>
<a href="https://github.com/sponsors/muhammad-fiaz"><img src="https://img.shields.io/badge/Sponsor-GitHub-pink?style=social&logo=github" alt="GitHub Sponsors"></a>
<a href="https://hits.sh/muhammad-fiaz/xz.zig/"><img src="https://hits.sh/muhammad-fiaz/xz.zig.svg?label=Visitors&extraCount=0&color=green" alt="Repo Visitors"></a>

<p><em>Native Zig XZ container compression library.</em></p>

<b><a href="https://muhammad-fiaz.github.io/xz.zig/">Documentation</a> |
<a href="https://muhammad-fiaz.github.io/xz.zig/api/">API Reference</a> |
<a href="https://muhammad-fiaz.github.io/xz.zig/guide/getting-started">Quick Start</a> |
<a href="CONTRIBUTING.md">Contributing</a></b>

</div>

`xz.zig` is a modern, high-performance XZ container compression library written in native Zig for **Zig 0.17.0 or later**. It implements the official XZ file format specification (Version 1.0.4) using [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig) as its underlying LZMA2 codec dependency.

> [!TIP]
> If you build with xz.zig, make sure to give it a star.

> [!NOTE]
> **Project maturity:** This project is production-ready, targeting stable **Zig 0.17.0 or later**. Implements the official XZ file format specification (Version 1.0.4) with zero runtime C dependencies, no `@cImport`, and no libc requirement (`link_libc = false`):
>
> **Comprehensive Native Subsystems:**
> - **Container Framing**: 12-byte stream header (`FD 37 7A 58 5A 00`), 12-byte stream footer (`59 5A`), and 4-byte block alignment.
> - **Integrity Checks**: Complete native implementation of all standard XZ checks: None, CRC32 (IEEE 802.3), CRC64 (ECMA-182 reversed polynomial `0xC96C5795D7870F42`), and cryptographic SHA-256.
> - **Variable-Length Integers**: 1-to-9 byte unsigned VLI encoding supporting integer values up to $2^{63}-1$.
> - **Index Parsing & Validation**: Real-time record tracking (`unpadded_size`, `uncompressed_size`), index padding verification, and footer backward-size consistency.
> - **Filter Pipelines**: Composable filter chains featuring primary LZMA2 (`0x21`), Delta byte distance filters (`0x03`), and x86 BCJ branch-call-jump address translation filters (`0x04`).
> - **Zero-Allocation Buffer Mode**: Caller-provided destination slices (`compressInto` and `decompressInto`).
> - **Streaming Pipelines**: Reader/writer streaming via `compressStream` and `decompressStream` for unbounded input streams.
> - **Safety & Decompression Bomb Protection**: Configurable `max_output_size` and `dict_size_limit` guards preventing malicious memory expansion.

**Related Zig projects:**

- For **LZMA / LZMA2 codec** support, check out **[lzma2.zig](https://github.com/muhammad-fiaz/lzma2.zig)**.
- For **HTTP client & server** support, check out **[httpx.zig](https://github.com/muhammad-fiaz/httpx.zig)**.
- For **Env.zig** (.env parsing), check out **[env.zig](https://github.com/muhammad-fiaz/env.zig)**.
- For **TUI** support, check out **[tui.zig](https://github.com/muhammad-fiaz/tui.zig)**.
- For **ZON file format** support, check out **[zon.zig](https://github.com/muhammad-fiaz/zon.zig)**.
- For **Spinners/loading/progress bar** support, check out **[loaders.zig](https://github.com/muhammad-fiaz/loaders.zig)**.
- For **Terminal colors & text styles** support, check out **[tint.zig](https://github.com/muhammad-fiaz/tint.zig)**.
- For **MCP** support, check out **[mcp.zig](https://github.com/muhammad-fiaz/mcp.zig)**.
- For **API framework** support, check out **[api.zig](https://github.com/muhammad-fiaz/api.zig)**.
- For **Web framework** support, check out **[zix](https://github.com/muhammad-fiaz/zix)**.
- For **archive/compression** support, check out **[archive.zig](https://github.com/muhammad-fiaz/archive.zig)**.
- For **compression file format** support, check out **[zigx](https://github.com/muhammad-fiaz/zigx)**.
- For **CUDA** support, check out **[cuda.zig](https://github.com/muhammad-fiaz/cuda.zig)**.
- For **Simplified build.zig config** support, check out **[buildx.zig](https://github.com/muhammad-fiaz/buildx.zig)**.
- For **SQLite (zig-native implementation)** support, check out **[sqlite.zig](https://github.com/muhammad-fiaz/sqlite.zig)**.
- For **File downloading** support, check out **[downloader.zig](https://github.com/muhammad-fiaz/downloader.zig)**.
- For **update checker/auto-updater** support, check out **[updater.zig](https://github.com/muhammad-fiaz/updater.zig)**.
- For **Numerical computing** support, check out **[num.zig](https://github.com/muhammad-fiaz/num.zig)**.
- For **Logging** support, check out **[logly.zig](https://github.com/muhammad-fiaz/logly.zig)**.
- For **Data validation and serialization** support, check out **[zigantic](https://github.com/muhammad-fiaz/zigantic)**.
- For **UUID** support, check out **[uuid.zig](https://github.com/muhammad-fiaz/uuid.zig)**.
- For **Key-Value database** support, check out **[zkv.zig](https://github.com/muhammad-fiaz/zkv.zig)**.
- For **Terminal color & text styles** support, check out **[hint.zig](https://github.com/muhammad-fiaz/hint.zig)**.
- For **Brotli compression** support, check out **[brotli.zig](https://github.com/muhammad-fiaz/brotli.zig)**.
- For **Zstd compression** support, check out **[zstd.zig](https://github.com/muhammad-fiaz/zstd.zig)**.
- For **Tree-Sitter** support, check out **[tree-sitter.zig](https://github.com/muhammad-fiaz/tree-sitter.zig)**.

---

<details>
<summary><strong>Features</strong> (click to expand)</summary>

| Feature | Description |
|---------|-------------|
| **Standard XZ Framing** | 12-byte stream header (`FD 37 7A 58 5A 00`), 12-byte stream footer (`59 5A`), and 4-byte block alignment |
| **Integrity Checks** | None, CRC32 (IEEE 802.3), CRC64 (ECMA-182 reversed polynomial), and SHA-256 block checksums |
| **Variable-Length Integers** | 1-to-9 byte unsigned VLI encoding supporting integer values up to $2^{63}-1$ |
| **Index Validation** | Real-time record tracking (`unpadded_size`, `uncompressed_size`), padding verification, backward size check |
| **Filter Chains** | Primary LZMA2 (`0x21`), Delta byte distance filters (`0x03`), and x86 BCJ branch address translation (`0x04`) |
| **One-Shot API** | Simple `xz.compress` and `xz.decompress` functions allocating directly via caller's allocator |
| **Zero-Allocation Mode** | Caller-provided destination slices (`compressInto` and `decompressInto`) for zero-heap embedded execution |
| **Streaming Pipelines** | Reader/writer streaming via `compressStream` and `decompressStream` for unbounded input streams |
| **Decompression Bomb Protection** | Configurable `max_output_size` and `dict_size_limit` guards preventing malicious memory expansion |
| **Zero C Dependencies** | 100% native Zig targeting Zig 0.17.0 without `@cImport` or external runtime libraries |

</details>

---

<details>
<summary><strong>Prerequisites and Supported Platforms</strong> (click to expand)</summary>

<br>

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Zig** | **0.17.0 or later** (required) | Download from [ziglang.org](https://ziglang.org/download/) |
| **Operating System** | Windows 10+, Linux, macOS, Freestanding | Native cross-platform support |

> [!IMPORTANT]
> **Zig 0.17.0 or later is required.** This project targets the stable Zig 0.17.0 and later releases. Earlier Zig versions (0.16.x or older) are not supported.

---

## Supported Platforms

| Platform | x86_64 (64-bit) | aarch64 (ARM64) | x86 (32-bit) | arm / thumb | riscv32 | freestanding |
|----------|:---------------:|:---------------:|:------------:|:-----------:|:-------:|:------------:|
| **Linux** | Yes | Yes | Yes | Yes | Yes | — |
| **Windows** | Yes | Yes | Yes | — | — | — |
| **macOS** | Yes | Yes (Apple Silicon) | — | — | — | — |
| **Freestanding** | — | — | Yes | — | — | Yes |

### Cross-Compilation

```bash
# Build for Linux ARM64 from Windows
zig build -Dtarget=aarch64-linux

# Build for Windows from Linux
zig build -Dtarget=x86_64-windows

# Build for macOS Apple Silicon from Linux
zig build -Dtarget=aarch64-macos

# Build for 32-bit Windows
zig build -Dtarget=x86-windows

# Build for freestanding embedded targets
zig build -Dtarget=x86-freestanding
```

</details>

---

## Installation

### Method 1: Zig Fetch (Recommended)

**Latest Release (0.0.1)**

```bash
zig fetch --save https://github.com/muhammad-fiaz/xz.zig/archive/refs/tags/0.0.1.tar.gz
```

> [!NOTE]
> Zig **0.17.0 or later** is required by **0.0.1**.

### Method 2: Zig Fetch (Latest Development Build)

Use this for the latest development build from the `main` branch:

```bash
zig fetch --save git+https://github.com/muhammad-fiaz/xz.zig.git
```

### Method 3: Manual `build.zig.zon` Configuration

```zig
.dependencies = .{
    .xz = .{
        .url = "https://github.com/muhammad-fiaz/xz.zig/archive/refs/tags/0.0.1.tar.gz",
        .hash = "...", // Run `zig fetch --save <url>` to generate the hash.
    },
},
```

### Method 4: Local Source Checkout

```bash
git clone https://github.com/muhammad-fiaz/xz.zig.git
cd xz.zig
zig build
```

To use a local checkout from another project:

```zig
.dependencies = .{
    .xz = .{
        .path = "../xz.zig",
    },
},
```

### Wire into `build.zig`

```zig
const xz_dep = b.dependency("xz", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("xz", xz_dep.module("xz"));
```

---

## Dependencies

`xz.zig` uses [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig) as a package dependency for raw LZMA2 chunk coding:

```text
Application ──> xz.zig (container format, framing, filters, checksums) ──> lzma2.zig (LZMA2 codec)
```

---

## Quick Start

### 1. Basic One-Shot Compression

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const text = "Native XZ container compression in pure Zig! High ratio and reliable checksums.";

    // Compress with default options (CRC64 integrity check)
    const compressed = try xz.compress(allocator, text, .{ .check = .crc64 });
    defer allocator.free(compressed);

    // Decompress
    const decompressed = try xz.decompress(allocator, compressed, .{});
    defer allocator.free(decompressed);

    std.debug.print("Restored: {s}\n", .{decompressed});
}
```

### 2. Caller-Provided Buffers (Zero Allocation)

```zig
var comp_buf: [1024]u8 = undefined;
const comp_len = try xz.compressInto(&comp_buf, text, .{ .check = .crc32 });

var decomp_buf: [1024]u8 = undefined;
const decomp_len = try xz.decompressInto(&decomp_buf, comp_buf[0..comp_len], .{});
```

### 3. Checksum Selection

```zig
// CRC32 check (4 bytes)
const c_crc32 = try xz.compress(allocator, text, .{ .check = .crc32 });

// CRC64 check (8 bytes, standard default in XZ)
const c_crc64 = try xz.compress(allocator, text, .{ .check = .crc64 });

// SHA-256 check (32 bytes cryptographic check)
const c_sha256 = try xz.compress(allocator, text, .{ .check = .sha256 });

// No integrity check (0 bytes)
const c_none = try xz.compress(allocator, text, .{ .check = .none });
```

### 4. Filter Chains (x86 BCJ and Delta)

```zig
// Pre-process x86 executable code before LZMA2 compression:
const filtered = try xz.compress(allocator, machine_code, .{
    .bcj_x86 = true,
    .check = .crc64,
});

// Pre-process byte-distance structured data:
const delta_comp = try xz.compress(allocator, sensor_samples, .{
    .delta_distance = 4, // 4-byte floating point or stereo channel stride
    .check = .crc64,
});
```

### 5. Incremental Streaming

```zig
// Reader/writer streaming
try xz.compressStream(allocator, &reader, &writer, .{ .check = .crc64 });
try xz.decompressStream(allocator, &comp_reader, &decomp_writer, .{});
```

### 6. Defensive Error Handling & Resource Limits

Handle corrupted containers, checksum mismatches, and defend against decompression bombs:

```zig
const result = xz.decompress(allocator, hostile_stream, .{
    .max_output_size = 16 * 1024 * 1024, // 16 MiB size cap
    .dict_size_limit = 32 * 1024 * 1024, // 32 MiB dictionary cap
});

if (result) |decompressed| {
    defer allocator.free(decompressed);
} else |err| switch (err) {
    error.ExceededOutputLimit => std.debug.print("Payload exceeded 16 MiB limit\n", .{}),
    error.ExceededMemoryLimit => std.debug.print("Payload exceeded dictionary memory limit\n", .{}),
    error.ChecksumMismatch => std.debug.print("Integrity check failed (CRC32/CRC64/SHA-256)\n", .{}),
    error.InvalidMagic => std.debug.print("Not a valid XZ container file\n", .{}),
    error.CorruptData => std.debug.print("Corrupted block or index records\n", .{}),
    else => std.debug.print("Decompression error: {}\n", .{err}),
}
```

---

## Cross-Tool Interoperability

Verification was executed against the official **XZ Utils** (`xz.exe` v5.8.1) and **7-Zip** (`7z.exe` v26.03) across 8 diverse fixtures and multiple check algorithms. Every fixture was tested bidirectionally across 6 validation paths:

| Fixture | Input Size | xz.zig $\to$ xz.exe (CRC64) | xz.zig $\to$ xz.exe (CRC32) | xz.zig $\to$ xz.exe (SHA-256) | xz.zig $\to$ 7-Zip | xz.exe $\to$ xz.zig | 7-Zip $\to$ xz.zig |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|
| **Empty** | 0 B | PASS | PASS | PASS | PASS | PASS | PASS |
| **One Byte** | 1 B | PASS | PASS | PASS | PASS | PASS | PASS |
| **Short String** | 32 B | PASS | PASS | PASS | PASS | PASS | PASS |
| **Repeated 'A'** | 4,096 B | PASS | PASS | PASS | PASS | PASS | PASS |
| **Natural Text** | 400 B | PASS | PASS | PASS | PASS | PASS | PASS |
| **Structured JSON** | 420 B | PASS | PASS | PASS | PASS | PASS | PASS |
| **Random Binary** | 16,384 B | PASS | PASS | PASS | PASS | PASS | PASS |
| **Boundary Data** | 65,537 B | PASS | PASS | PASS | PASS | PASS | PASS |

> **Result**: **48 / 48 tests passed (100% bit-perfect match)** with zero warnings or errors.

---

## Runnable Examples

The `examples/` directory contains complete, standalone Zig 0.17.0 programs:

| Example | File | Description |
|---|---|---|
| `basic_compression` | [`examples/basic_compression.zig`](examples/basic_compression.zig) | One-shot XZ compression and decompression roundtrip |
| `caller_buffer` | [`examples/caller_buffer.zig`](examples/caller_buffer.zig) | Zero-allocation stack buffer operations |
| `streaming_pipeline` | [`examples/streaming_pipeline.zig`](examples/streaming_pipeline.zig) | Reader/writer stream pipeline |
| `checksum_types` | [`examples/checksum_types.zig`](examples/checksum_types.zig) | CRC32, CRC64, SHA-256, and None integrity checks |
| `filter_chains` | [`examples/filter_chains.zig`](examples/filter_chains.zig) | x86 BCJ branch filter and Delta byte-distance filter chains |
| `error_handling` | [`examples/error_handling.zig`](examples/error_handling.zig) | Magic errors, corrupt payloads, and buffer limits |

Run any example:
```bash
zig build run-basic_compression
zig build run-caller_buffer
zig build run-streaming_pipeline
zig build run-checksum_types
zig build run-filter_chains
zig build run-error_handling
zig build run-all-examples   # Run all examples in sequence
```

---

## Validation Matrix & Testing

```bash
zig build                    # Build static library (libxz)
zig build test --summary all # Run all native unit tests
zig build fuzz               # Run fuzz and edge-case validation suite
zig build check              # Validate compilation across all targets
zig fmt --check src/ examples/ build.zig build.zig.zon
```

---

## Security & Resource Management

`xz.zig` is designed to process untrusted inputs safely. Key protections include:

| Protection | Mechanism |
|---|---|
| **Decompression Bomb (CWE-409)** | `DecompressOptions.max_output_size` caps uncompressed output; `error.ExceededOutputLimit` on breach |
| **Dictionary Memory Bounds** | `DecompressOptions.dict_size_limit` restricts peak allocation before dictionary is created |
| **Zero-Allocation Execution** | `compressInto` / `decompressInto` operate on caller buffers with no heap use; `error.OutputTooSmall` on overflow |
| **Checksums** | IEEE 802.3 CRC32, ECMA-182 CRC64, and SHA-256 per-block integrity (`error.ChecksumMismatch`) |
| **Frame Validation** | Header/footer magic, block header CRC32, VLI bounds, index consistency, and backward size cross-checking |

See [SECURITY.md](SECURITY.md) for vulnerability reporting guidelines and full resource-exhaustion guidance.

---


## Format Distinctions

Understanding the relationship between raw codecs and archive/container layers:

| Format | Magic / Header | Block Framing & Padding | Integrity Check | Package |
|---|---|---|---|---|
| **Raw LZMA2** | Per-chunk control bytes | Byte-stream chunks (`0x00` EOS) | None | [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig) |
| **Legacy `.lzma`** | 13-byte Alone header | Single continuous stream | None / EOS marker | [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig) |
| **`.xz` Container** | `FD 37 7A 58 5A 00` | Multi-block, 4-byte padded, Index | CRC32, CRC64, SHA-256 | [`xz.zig`](https://github.com/muhammad-fiaz/xz.zig) |

---

## Project Structure

```text
xz.zig/
├── src/
│   ├── root.zig                    # Root package re-exports
│   ├── xz.zig                      # Public API entry point
│   ├── options.zig                 # CheckType, CompressOptions, DecompressOptions
│   ├── errors.zig                  # Structured typed error sets
│   ├── checksum/
│   │   ├── crc32.zig               # IEEE 802.3 CRC32 (polynomial 0xEDB88320)
│   │   ├── crc64.zig               # ECMA-182 CRC64 (polynomial 0xC96C5795D7870F42)
│   │   └── sha256.zig              # Cryptographic SHA-256 block check
│   ├── format/
│   │   ├── vli.zig                 # Variable-Length Integer codec
│   │   ├── padding.zig             # 4-byte block & index alignment validation
│   │   ├── stream_flags.zig        # Stream flags encoding & check ID mapping
│   │   ├── stream_header.zig       # 12-byte stream header parser/serializer
│   │   ├── stream_footer.zig       # 12-byte stream footer & backward size validator
│   │   ├── block_header.zig        # Block flags, filter chains, header CRC32
│   │   └── index.zig               # Index record serializer, parser, and CRC32
│   ├── filters/
│   │   ├── filter.zig              # Filter ID registry & validation
│   │   ├── lzma2.zig               # LZMA2 bridge importing lzma2.zig package
│   │   ├── delta.zig               # Byte distance filter (distance 1..256)
│   │   └── bcj.zig                 # x86 BCJ branch address translator
│   ├── compress/
│   │   ├── block.zig               # Block serialization, filter execution, check calculation
│   │   ├── stream.zig              # One-shot stream compressor & compressInto
│   │   └── streaming.zig           # Incremental StreamingCompressor & compressStream
│   └── decompress/
│       ├── block.zig               # Block deserialization, check verification, filter reversal
│       ├── stream.zig              # One-shot stream decompressor & decompressInto
│       └── streaming.zig           # Incremental decompressStream
├── examples/                       # Standalone runnable examples
│   ├── basic_compression.zig       # Standard one-shot XZ compression
│   ├── caller_buffer.zig           # Stack-allocated zero-heap buffer usage
│   ├── streaming_pipeline.zig      # Reader/writer stream pipeline
│   ├── checksum_types.zig          # None, CRC32, CRC64, and SHA-256 integrity checks
│   ├── filter_chains.zig           # x86 BCJ + LZMA2 and Delta + LZMA2 pipelines
│   └── error_handling.zig          # Magic errors, corrupt payloads, buffer limits
├── docs/                           # VitePress documentation portal
├── build.zig                       # Build system definition
├── build.zig.zon                   # Package metadata
├── README.md
├── SECURITY.md
├── LICENSE
└── CONTRIBUTING.md
```

---

## Documentation & API Reference

Comprehensive documentation and guides are provided in `docs/`:

- [Documentation Portal](https://muhammad-fiaz.github.io/xz.zig/)
- Local documentation build:
  ```bash
  cd docs && bun install && bun run build
  ```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `zig build test --summary all`
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for code style guidelines and testing requirements.

## License

MIT License - see [LICENSE](LICENSE) for details.
