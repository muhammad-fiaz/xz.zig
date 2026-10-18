//! 4-byte alignment and padding helpers for XZ blocks and indexes.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");

/// Calculates the number of null bytes (0..3) needed to round `len` up to a multiple of 4.
pub fn pad4(len: usize) usize {
    return std.mem.alignForward(usize, len, 4) - len;
}

/// Validates that all bytes in `slice` are 0x00. Returns error.InvalidPadding if any non-zero byte is found.
pub fn validatePadding(slice: []const u8) errors.FormatError!void {
    if (!std.mem.allEqual(u8, slice, 0x00)) return error.InvalidPadding;
}

test "padding: pad4 calculation" {
    try std.testing.expectEqual(@as(usize, 0), pad4(0));
    try std.testing.expectEqual(@as(usize, 3), pad4(1));
    try std.testing.expectEqual(@as(usize, 2), pad4(2));
    try std.testing.expectEqual(@as(usize, 1), pad4(3));
    try std.testing.expectEqual(@as(usize, 0), pad4(4));
    try std.testing.expectEqual(@as(usize, 0), pad4(1024));
}
