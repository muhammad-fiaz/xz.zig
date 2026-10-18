//! XZ CRC64 calculation using the ECMA-182 reversed polynomial 0xC96C5795D7870F42.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");

/// Computes the XZ CRC64 checksum of a byte slice using standard library std.hash.crc.@"CRC-64/XZ".
pub fn hash(data: []const u8) u64 {
    return std.hash.crc.@"CRC-64/XZ".hash(data);
}

/// Updates an existing CRC64 value with additional data using standard library std.hash.crc.@"CRC-64/XZ".
pub fn update(current_crc: u64, data: []const u8) u64 {
    var c = std.hash.crc.@"CRC-64/XZ"{ .crc = ~current_crc };
    c.update(data);
    return c.final();
}

test "crc64: official xz test vector" {
    const data = "123456789";
    const expected: u64 = 0x995DC9BBDF1939FA;
    try std.testing.expectEqual(expected, hash(data));

    const p1 = "1234";
    const p2 = "56789";
    const c1 = hash(p1);
    try std.testing.expectEqual(expected, update(c1, p2));
}
