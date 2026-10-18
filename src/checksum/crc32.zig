//! Standard IEEE 802.3 CRC32 calculation for XZ headers and blocks.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");

/// Computes IEEE 802.3 CRC32 checksum over the provided byte slice using std.hash.Crc32.
pub fn hash(data: []const u8) u32 {
    return std.hash.Crc32.hash(data);
}

/// Updates an existing CRC32 value with additional data using std.hash.Crc32.
pub fn update(current_crc: u32, data: []const u8) u32 {
    var c = std.hash.Crc32{ .crc = ~current_crc };
    c.update(data);
    return c.final();
}

test "crc32: standard vector" {
    const data = "123456789";
    const expected: u32 = 0xCBF43926;
    try std.testing.expectEqual(expected, hash(data));

    const p1 = "1234";
    const p2 = "56789";
    const c1 = hash(p1);
    try std.testing.expectEqual(expected, update(c1, p2));
}
