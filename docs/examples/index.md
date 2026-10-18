# Examples Overview

The `examples/` directory contains standalone, compiling example programs showcasing real-world usage of `xz.zig` across container compression, integrity checks, filter pipelines, caller buffers, and streaming I/O.

Every example file can be compiled and executed directly via `zig build`:

```bash
zig build run-basic_compression
zig build run-caller_buffer
zig build run-checksum_types
zig build run-filter_chains
zig build run-streaming_pipeline
zig build run-error_handling
zig build run-all-examples
```

---

## Example Directory

| Example Guide | Source File | Features Covered | Memory Model |
|---|---|---|---|
| [**Basic Compression**](./basic_compression.md) | [`examples/basic_compression.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/basic_compression.zig) | One-shot XZ stream compression and decompression | Dynamic allocation |
| [**Caller Buffers**](./caller_buffer.md) | [`examples/caller_buffer.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/caller_buffer.zig) | `compressInto`, `decompressInto` | **Zero-allocation** (Stack / fixed buffers) |
| [**Checksum Types**](./checksum_types.md) | [`examples/checksum_types.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/checksum_types.zig) | None, CRC32, CRC64, and SHA-256 block check algorithms | Dynamic allocation |
| [**Filter Chains**](./filter_chains.md) | [`examples/filter_chains.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/filter_chains.zig) | x86 BCJ branch filter and Delta byte-stride filter | Dynamic allocation |
| [**Streaming Pipeline**](./streaming_pipeline.md) | [`examples/streaming_pipeline.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/streaming_pipeline.zig) | `compressStream`, `decompressStream` reader/writer pipelines | Bounded-memory streaming |
| [**Error Handling**](./error_handling.md) | [`examples/error_handling.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/error_handling.zig) | Corrupt magic, checksum mismatch, buffer bounds | Defensive error verification |

---

## What Each Example Covers

### 1. [Basic Compression](./basic_compression.md)
Demonstrates standard heap-allocated XZ file compression and decompression using `xz.compress` and `xz.decompress`.

### 2. [Caller-Provided Buffers](./caller_buffer.md)
Demonstrates zero-allocation operations using pre-allocated stack buffers via `xz.compressInto` and `xz.decompressInto`.

### 3. [Checksum Types](./checksum_types.md)
Demonstrates configuring block integrity checks across all standard algorithms: None (0B), CRC32 (4B), CRC64 (8B, standard default), and SHA-256 (32B).

### 4. [Filter Chains](./filter_chains.md)
Demonstrates pre-processing filters before LZMA2 compression:
- x86 BCJ branch address normalization for native binary executables
- Delta byte-stride filtering for multi-channel audio or numeric tables

### 5. [Streaming Pipeline](./streaming_pipeline.md)
Demonstrates incremental processing of unbounded streams using standard reader/writer interfaces with `xz.compressStream` and `xz.decompressStream`.

### 6. [Error Handling & Defense](./error_handling.md)
Demonstrates robust handling of invalid container magic, corrupted block payloads (checksum mismatch), and undersized buffers.
