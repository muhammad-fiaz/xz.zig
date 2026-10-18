const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const data = "Testing all XZ integrity check types: None, CRC32, CRC64, and SHA-256.";
    const check_types = [_]xz.CheckType{ .none, .crc32, .crc64, .sha256 };

    for (check_types) |c| {
        const compressed = try xz.compress(allocator, data, .{ .check = c });
        defer allocator.free(compressed);

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
