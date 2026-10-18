# XZ Compression Guide

`xz.zig` offers high-ratio, specification-compliant XZ container compression with flexible integrity checks, composable pre-filters, and both allocating and zero-allocation caller-buffer operations.

---

## 1. One-Shot Compression

The simplest way to compress data into an XZ container is using `xz.compress()`:

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const input = "Data to compress in XZ format...";

    const compressed = try xz.compress(allocator, input, .{ .check = .crc64 });
    defer allocator.free(compressed);

    std.debug.print("XZ container compressed size: {d} bytes\n", .{compressed.len});
}
```

The returned buffer is a complete `.xz` file containing the Stream Header, Block Header, LZMA2 payload, Block Padding, CRC64 Check, Index, and Stream Footer.

---

## 2. Integrity Check Options

The `CheckType` enum allows selecting the integrity check algorithm used for block validation:

| Check Type | Check Size | Description |
|---|---|---|
| `.crc64` | 8 bytes | ECMA-182 reversed polynomial. Standard default for `.xz` files. |
| `.crc32` | 4 bytes | IEEE 802.3 standard cyclic redundancy check. |
| `.sha256` | 32 bytes | Cryptographic SHA-256 hash for maximum tamper resistance. |
| `.none` | 0 bytes | Omit block integrity checks for minimal overhead. |

Example:

```zig
const c_sha = try xz.compress(allocator, input, .{
    .check = .sha256,
});
defer allocator.free(c_sha);
```

---

## 3. Filter Chains: BCJ & Delta

Pre-processing filters transform repetitive binary structures before LZMA2 compression, improving compression ratios.

### 3.1. x86 BCJ Branch Filter (`0x04`)

Converts x86/x86_64 relative jump and call targets (`0xE8` and `0xE9` instructions) to absolute addresses. This dramatically improves compression for compiled native executables:

```zig
const exe_compressed = try xz.compress(allocator, compiled_binary, .{
    .enable_bcj_x86 = true,
    .check = .crc64,
});
defer allocator.free(exe_compressed);
```

### 3.2. Delta Filter (`0x03`)

Computes byte differences across a fixed byte stride ($1 \le \text{distance} \le 256$). Highly effective for uncompressed audio, RGB bitmaps, or structured numeric tables:

```zig
const audio_compressed = try xz.compress(allocator, pcm_stereo_samples, .{
    .delta_distance = 4, // 16-bit stereo stride (2 channels * 2 bytes)
    .check = .crc64,
});
defer allocator.free(audio_compressed);
```

---

## 4. Zero-Allocation Caller Buffers

For embedded or latency-critical applications, `xz.compressInto()` avoids dynamic heap allocation:

```zig
var out_buffer: [4096]u8 = undefined;
const bytes_written = try xz.compressInto(&out_buffer, input, .{
    .check = .crc32,
});

const compressed_slice = out_buffer[0..bytes_written];
```

If `out_buffer` is too small to fit the stream headers, block overhead, compressed payload, and footer, `error.OutputTooSmall` is returned.

---

## 5. Streaming Compression

For arbitrarily large inputs or network streams where data cannot fit in memory:

```zig
try xz.compressStream(allocator, &reader, &writer, .{
    .check = .crc64,
});
```
