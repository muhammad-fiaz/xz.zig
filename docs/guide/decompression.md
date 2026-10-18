# XZ Decompression Guide

`xz.zig` provides a robust, defensive decoder for the `.xz` file format. It parses container headers, validates block-level and stream-level integrity checksums, reverses pre-filters (BCJ and Delta), and restores uncompressed payloads with strict resource limits.

---

## 1. One-Shot Decompression

The simplest way to decode an `.xz` file is using `xz.decompress()`:

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const decompressed = try xz.decompress(allocator, xz_bytes, .{});
    defer allocator.free(decompressed);

    std.debug.print("Restored: {s}\n", .{decompressed});
}
```

The decoder automatically:
1. Validates the 12-byte Stream Header magic and CRC32.
2. Extracts and checks Stream Flags.
3. Parses the 12-byte Stream Footer, validates footer CRC32, and verifies backward size.
4. Reads and validates the Index and verifies block record counts.
5. Processes each Block, decoding filters in reverse order.
6. Computes and compares the Block Check (CRC32, CRC64, or SHA-256).

---

## 2. Zero-Allocation Caller Buffers

When decoding into an existing stack or caller-managed buffer, use `xz.decompressInto()`:

```zig
var restored_buf: [1024]u8 = undefined;
const decomp_len = try xz.decompressInto(&restored_buf, xz_bytes, .{});

const restored_slice = restored_buf[0..decomp_len];
```

If the provided destination slice is smaller than the unpacked stream, `error.OutputTooSmall` is returned.

---

## 3. Protecting Against Decompression Bombs

Hostile payloads can be designed to expand into gigabytes of data. `xz.zig` defends against resource exhaustion attacks via `max_output_size`:

```zig
const decompressed = try xz.decompress(allocator, untrusted_bytes, .{
    .max_output_size = 50 * 1024 * 1024, // 50 MiB upper limit
}) catch |err| switch (err) {
    error.ExceededOutputLimit => {
        std.debug.print("Decompression aborted: payload exceeded limit!\n", .{});
        return;
    },
    else => return err,
};
defer allocator.free(decompressed);
```

---

## 4. Detecting XZ Streams

Before initiating decompression, you can quickly verify whether a byte slice begins with valid XZ magic bytes using `xz.isXzStream`:

```zig
if (!xz.isXzStream(maybe_xz)) {
    std.debug.print("Not a valid XZ file!\n", .{});
    return;
}
```

---

## 5. Streaming Decompression

For processing continuous network data or files that exceed system RAM:

```zig
try xz.decompressStream(allocator, &comp_reader, &decomp_writer, .{});
```
