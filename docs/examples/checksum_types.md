# Checksum Types Example

This example demonstrates configuring block integrity checks across all standard XZ algorithms: None, CRC32, CRC64, and SHA-256.

Source file: [`examples/checksum_types.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/checksum_types.zig)

---

## Complete Source Code

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const data = "Testing all XZ integrity check types: None, CRC32, CRC64, and SHA-256.";
    const check_types = [_]xz.CheckType{ .none, .crc32, .crc64, .sha256 };

    for (check_types) |c| {
        // Compress with specific check type
        const compressed = try xz.compress(allocator, data, .{ .check = c });
        defer allocator.free(compressed);

        // Decompress and verify
        const decompressed = try xz.decompress(allocator, compressed, .{ .verify_checksum = true });
        defer allocator.free(decompressed);

        std.debug.print("Check {s: <7} (size {d: >2}B) | Comp: {d: >3}B | Verify: PASS\n", .{
            @tagName(c),
            c.checkSize(),
            compressed.len,
        });
    }

    std.debug.print("All integrity check types verified successfully!\n", .{});
}
```

---

## How to Run

Compile and run this example using the Zig build system:

```bash
zig build run-checksum_types
```

### Expected Output

```text
Check none    (size  0B) | Comp: 120B | Verify: PASS
Check crc32   (size  4B) | Comp: 124B | Verify: PASS
Check crc64   (size  8B) | Comp: 128B | Verify: PASS
Check sha256  (size 32B) | Comp: 152B | Verify: PASS
All integrity check types verified successfully!
```
