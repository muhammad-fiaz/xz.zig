//! Variable-Length Integer (VLI) encoding and decoding for XZ streams.
//!
//! Section 1.2 of the .xz File Format Specification.
//! Integers in [0, 2^63 - 1] are encoded in 1 to 9 bytes.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");

pub const VLI_MAX: u64 = 0x7FFFFFFFFFFFFFFF;
pub const VLI_BYTES_MAX: usize = 9;

/// Encodes an integer into XZ variable-length format.
/// Returns number of bytes written into `buf`.
pub fn encode(buf: []u8, num: u64) errors.FormatError!usize {
    if (num > VLI_MAX) return error.InvalidVli;
    if (buf.len == 0) return error.InvalidVli;

    var n = num;
    var i: usize = 0;
    while (n >= 0x80) {
        if (i >= buf.len) return error.InvalidVli;
        buf[i] = @as(u8, @truncate(n)) | 0x80;
        i += 1;
        n >>= 7;
    }

    if (i >= buf.len) return error.InvalidVli;
    buf[i] = @as(u8, @truncate(n));
    return i + 1;
}

/// Decodes an integer from XZ variable-length format.
/// Returns the number of bytes consumed.
pub fn decode(buf: []const u8, out_val: *u64) errors.FormatError!usize {
    if (buf.len == 0) return error.TruncatedInput;

    const max_len = @min(buf.len, VLI_BYTES_MAX);
    var val: u64 = buf[0] & 0x7F;
    var i: usize = 1;

    while (i <= max_len) {
        if ((buf[i - 1] & 0x80) == 0) {
            // XZ Spec 1.2: integers must be encoded in the minimum number of bytes (no padding zeros)
            if (i > 1 and buf[i - 1] == 0x00) return error.InvalidVli;
            out_val.* = val;
            return i;
        }
        if (i >= max_len) {
            if (buf.len < VLI_BYTES_MAX) return error.TruncatedInput;
            return error.InvalidVli;
        }
        val |= @as(u64, buf[i] & 0x7F) << @as(u6, @intCast(i * 7));
        i += 1;
    }

    return error.InvalidVli;
}

/// Returns the number of bytes required to encode `num`.
pub fn size(num: u64) usize {
    if (num > VLI_MAX) return 0;
    var n = num;
    var count: usize = 0;
    while (true) {
        count += 1;
        n >>= 7;
        if (n == 0) break;
    }
    return count;
}

test "vli: encode and decode roundtrip" {
    var buf: [16]u8 = undefined;
    const test_values = [_]u64{
        0,
        1,
        127,
        128,
        255,
        16383,
        16384,
        1048576,
        VLI_MAX,
    };

    for (test_values) |val| {
        const enc_len = try encode(&buf, val);
        try std.testing.expectEqual(size(val), enc_len);

        var decoded: u64 = 0;
        const dec_len = try decode(buf[0..enc_len], &decoded);
        try std.testing.expectEqual(enc_len, dec_len);
        try std.testing.expectEqual(val, decoded);
    }
}
