# Getting Started with `xz.zig`

`xz.zig` provides a pure, native Zig implementation of the XZ container file format for **Zig 0.17.0**. It has zero external C dependencies, uses no `@cImport`, and imports [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig) as its codec dependency for raw LZMA2 chunk coding.

---

## 1. Quick Example

Here is a minimal, complete example showing compression and decompression of a standard XZ container stream:

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const message = "Native XZ container compression in pure Zig 0.17.0! High-ratio dictionary encoding with CRC64.";

    // 1. One-shot compression (standard CRC64 check)
    const compressed = try xz.compress(allocator, message, .{ .check = .crc64 });
    defer allocator.free(compressed);

    // 2. One-shot decompression
    const decompressed = try xz.decompress(allocator, compressed, .{});
    defer allocator.free(decompressed);

    std.debug.print("Original:     {s}\n", .{message});
    std.debug.print("Compressed:   {d} bytes\n", .{compressed.len});
    std.debug.print("Decompressed: {s}\n", .{decompressed});
}
```

---

## 2. Allocator Management & Ownership

- **`xz.compress(allocator, src, options)`**:
  Allocates a slice of memory containing the complete XZ stream (Stream Header, Block Header, Compressed Data, Block Padding, Check, Index, Stream Footer). The caller owns the returned slice and must free it using `allocator.free()`.
- **`xz.decompress(allocator, src, options)`**:
  Allocates a slice of memory containing the restored uncompressed data. The caller owns the returned slice and must free it using `allocator.free()`.
- **Caller-Buffer Operations**:
  If you prefer not to allocate memory on the heap, use `xz.compressInto(dst, src, options)` and `xz.decompressInto(dst, src, options)`. These operate entirely on user-provided slices and perform zero heap allocations.

---

## 3. Supported Integrity Checks

XZ supports multiple integrity verification algorithms per block:

```zig
// CRC64 (standard default in .xz files)
const c_crc64 = try xz.compress(allocator, message, .{ .check = .crc64 });

// CRC32 (standard IEEE 802.3 4-byte check)
const c_crc32 = try xz.compress(allocator, message, .{ .check = .crc32 });

// SHA-256 (32-byte cryptographic hash)
const c_sha256 = try xz.compress(allocator, message, .{ .check = .sha256 });

// None (zero checksum bytes)
const c_none = try xz.compress(allocator, message, .{ .check = .none });
```

---

## 4. Next Steps

- Check out the [Installation Guide](./installation.md) to add `xz.zig` to your `build.zig.zon`.
- Read [Container Format & Framing](./format-notes.md) to understand XZ stream structures.
- Explore the [API Reference](/api/) for detailed type and function specifications.
