# Zero-Allocation Caller-Provided Buffers

This example demonstrates using pre-allocated stack buffers with `xz.compressInto` and `xz.decompressInto` to achieve zero dynamic heap allocations.

Source file: [`examples/caller_buffer.zig`](https://github.com/muhammad-fiaz/xz.zig/blob/main/examples/caller_buffer.zig)

---

## Complete Source Code

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const message = "Zero-allocation embedded XZ container compression using pre-allocated caller buffers.";

    var comp_buffer: [1024]u8 = undefined;
    var decomp_buffer: [1024]u8 = undefined;

    // 1. Compress directly into caller buffer
    const comp_size = try xz.compressInto(message, &comp_buffer, .{});
    std.debug.print("Compressed into caller buffer: {d} bytes\n", .{comp_size});

    // 2. Decompress directly into caller buffer
    const decomp_size = try xz.decompressInto(comp_buffer[0..comp_size], &decomp_buffer, .{});
    std.debug.print("Decompressed into caller buffer: {d} bytes\n", .{decomp_size});

    const matches = std.mem.eql(u8, message, decomp_buffer[0..decomp_size]);
    std.debug.print("Verification: {}\n", .{matches});

    std.debug.print("Caller-buffer operations completed successfully!\n", .{});
}
```

---

## How to Run

Compile and run this example using the Zig build system:

```bash
zig build run-caller_buffer
```

### Expected Output

```text
Compressed into caller buffer: 132 bytes
Decompressed into caller buffer: 85 bytes
Verification: true
Caller-buffer operations completed successfully!
```
