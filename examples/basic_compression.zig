const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const sample = "High performance native Zig XZ compression library powered by lzma2.zig.";

    // One-shot compression with default CRC64 check
    const compressed = try xz.compress(allocator, sample, .{});
    defer allocator.free(compressed);

    std.debug.print("Original size: {d} bytes\n", .{sample.len});
    std.debug.print("XZ compressed size: {d} bytes\n", .{compressed.len});
    std.debug.print("Is valid XZ stream: {}\n", .{xz.isXzStream(compressed)});

    // One-shot decompression
    const decompressed = try xz.decompress(allocator, compressed, .{});
    defer allocator.free(decompressed);

    std.debug.print("Decompressed size: {d} bytes\n", .{decompressed.len});
    std.debug.print("Content matches: {}\n", .{std.mem.eql(u8, sample, decompressed)});

    std.debug.print("XZ basic compression example completed successfully!\n", .{});
}
