# Filter Chains (x86 BCJ & Delta) Example

This example demonstrates using pre-filters in the XZ pipeline before LZMA2 compression:
1. **x86 BCJ Filter**: Converts relative jump/call targets to absolute addresses.
2. **Delta Filter**: Computes byte-stride differences on correlated data.

Source file: [`examples/filter_chains.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/filter_chains.zig)

---

## Complete Source Code

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    std.debug.print("--- 1. Testing x86 BCJ + LZMA2 Filter Chain ---\n", .{});
    // Synthetic x86 machine code pattern with relative call (E8) and jump (E9) instructions
    var x86_code = [_]u8{
        0x55, 0x89, 0xE5, 0x83, 0xEC, 0x10, 0xE8, 0x40, 0x00, 0x00, 0x00, 0x89, 0xC3,
        0xE9, 0x10, 0x01, 0x00, 0x00, 0x90, 0x90, 0xC9, 0xC3,
    };

    const comp_bcj = try xz.compress(allocator, &x86_code, .{ .bcj_x86 = true });
    defer allocator.free(comp_bcj);
    const decomp_bcj = try xz.decompress(allocator, comp_bcj, .{});
    defer allocator.free(decomp_bcj);

    std.debug.print("BCJ + LZMA2 roundtrip: {}\n", .{std.mem.eql(u8, &x86_code, decomp_bcj)});

    std.debug.print("--- 2. Testing Delta + LZMA2 Filter Chain ---\n", .{});
    // Correlated sensor data pattern
    var sensor_data: [128]u8 = undefined;
    for (0..sensor_data.len) |i| {
        sensor_data[i] = @as(u8, @truncate(i * 4));
    }

    const comp_delta = try xz.compress(allocator, &sensor_data, .{ .delta_distance = 1 });
    defer allocator.free(comp_delta);
    const decomp_delta = try xz.decompress(allocator, comp_delta, .{});
    defer allocator.free(decomp_delta);

    std.debug.print("Delta + LZMA2 roundtrip: {}\n", .{std.mem.eql(u8, &sensor_data, decomp_delta)});

    std.debug.print("Filter chain example completed successfully!\n", .{});
}
```

---

## How to Run

Compile and run this example using the Zig build system:

```bash
zig build run-filter_chains
```

### Expected Output

```text
--- 1. Testing x86 BCJ + LZMA2 Filter Chain ---
BCJ + LZMA2 roundtrip: true
--- 2. Testing Delta + LZMA2 Filter Chain ---
Delta + LZMA2 roundtrip: true
Filter chain example completed successfully!
```
