//! SHA-256 integrity check for XZ blocks.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");

pub const Sha256 = std.crypto.hash.sha2.Sha256;

/// Computes the 32-byte SHA-256 digest of a byte slice.
pub fn hash(data: []const u8) [32]u8 {
    var digest: [32]u8 = undefined;
    Sha256.hash(data, &digest, .{});
    return digest;
}

test "sha256: standard vector" {
    const data = "123456789";
    const digest = hash(data);
    // sha256("123456789") = 15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225
    const expected = [_]u8{
        0x15, 0xe2, 0xb0, 0xd3, 0xc3, 0x38, 0x91, 0xeb,
        0xb0, 0xf1, 0xef, 0x60, 0x9e, 0xc4, 0x19, 0x42,
        0x0c, 0x20, 0xe3, 0x20, 0xce, 0x94, 0xc6, 0x5f,
        0xbc, 0x8c, 0x33, 0x12, 0x44, 0x8e, 0xb2, 0x25,
    };
    try std.testing.expectEqualSlices(u8, &expected, &digest);
}
