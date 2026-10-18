const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const sample = "Error handling and malformed input testing.";
    const valid_xz = try xz.compress(allocator, sample, .{});
    defer allocator.free(valid_xz);

    std.debug.print("1. Testing invalid magic bytes...\n", .{});
    const bad_magic = try allocator.dupe(u8, valid_xz);
    defer allocator.free(bad_magic);
    bad_magic[0] = 0xAA; // Corrupt first magic byte

    if (xz.decompress(allocator, bad_magic, .{})) |_| {
        @panic("Expected InvalidMagic error");
    } else |err| {
        std.debug.print("   Correctly caught error: {s}\n", .{@errorName(err)});
    }

    std.debug.print("2. Testing corrupted block payload (checksum mismatch)...\n", .{});
    const bad_payload = try allocator.dupe(u8, valid_xz);
    defer allocator.free(bad_payload);
    bad_payload[20] ^= 0xFF; // Flip bits in compressed block

    if (xz.decompress(allocator, bad_payload, .{})) |_| {
        @panic("Expected ChecksumMismatch or CorruptData");
    } else |err| {
        std.debug.print("   Correctly caught error: {s}\n", .{@errorName(err)});
    }

    std.debug.print("3. Testing small buffer with compressInto...\n", .{});
    var tiny_buf: [16]u8 = undefined;
    if (xz.compressInto(sample, &tiny_buf, .{})) |_| {
        @panic("Expected OutputTooSmall error");
    } else |err| {
        std.debug.print("   Correctly caught error: {s}\n", .{@errorName(err)});
    }

    std.debug.print("All error handling checks passed!\n", .{});
}
