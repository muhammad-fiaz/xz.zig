//! Stream Flags encoding and decoding (Section 2.1.1.2).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const options = @import("../options.zig");
const CheckType = options.CheckType;

/// Encodes CheckType into the 2-byte XZ Stream Flags field.
pub fn encode(check: CheckType) [2]u8 {
    return [2]u8{ 0x00, @backingInt(check) & 0x0F };
}

/// Decodes and validates the 2-byte XZ Stream Flags field.
pub fn decode(bytes: [2]u8) (errors.FormatError || errors.ChecksumError)!CheckType {
    if (bytes[0] != 0x00) return error.InvalidFlags;
    if ((bytes[1] & 0xF0) != 0x00) return error.InvalidFlags; // Reserved bits must be 0

    const check_raw = bytes[1] & 0x0F;
    return switch (check_raw) {
        0x00 => .none,
        0x01 => .crc32,
        0x04 => .crc64,
        0x0A => .sha256,
        else => error.UnsupportedCheck,
    };
}

test "stream_flags: roundtrip" {
    const checks = [_]CheckType{ .none, .crc32, .crc64, .sha256 };
    for (checks) |c| {
        const enc = encode(c);
        const dec = try decode(enc);
        try std.testing.expectEqual(c, dec);
    }
}
