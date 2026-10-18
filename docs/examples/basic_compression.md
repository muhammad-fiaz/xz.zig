# Basic Compression & Decompression Example

This example demonstrates one-shot in-memory compression and decompression of a standard `.xz` container file using `xz.zig`.

Source file: [`examples/basic_compression.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/basic_compression.zig)

---

## Complete Source Code

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const sample = "High performance native Zig XZ compression library powered by lzma2.zig.";

    // 1. One-shot compression with default CRC64 check
    const compressed = try xz.compress(allocator, sample, .{});
    defer allocator.free(compressed);

    std.debug.print("Original size: {d} bytes\n", .{sample.len});
    std.debug.print("XZ compressed size: {d} bytes\n", .{compressed.len});
    std.debug.print("Is valid XZ stream: {}\n", .{xz.isXzStream(compressed)});

    // 2. One-shot decompression
    const decompressed = try xz.decompress(allocator, compressed, .{});
    defer allocator.free(decompressed);

    std.debug.print("Decompressed size: {d} bytes\n", .{decompressed.len});
    std.debug.print("Content matches: {}\n", .{std.mem.eql(u8, sample, decompressed)});

    std.debug.print("XZ basic compression example completed successfully!\n", .{});
}
```

---

## How to Run

Compile and run this example using the Zig build system:

```bash
zig build run-basic_compression
```

### Expected Output

```text
Original size: 72 bytes
XZ compressed size: 128 bytes
Is valid XZ stream: true
Decompressed size: 72 bytes
Content matches: true
XZ basic compression example completed successfully!
```
