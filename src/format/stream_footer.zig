//! Stream Footer encoding and decoding (Section 2.1.2).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const options = @import("../options.zig");
const CheckType = options.CheckType;
const stream_flags = @import("stream_flags.zig");
const crc32 = @import("../checksum/crc32.zig");

pub const FOOTER_SIZE: usize = 12;
pub const FOOTER_MAGIC = [2]u8{ 'Y', 'Z' }; // 0x59, 0x5A

pub const FooterInfo = struct {
    check: CheckType,
    backward_size: u32,
    index_size: usize,
};

/// Encodes an XZ Stream Footer given the check type and real index size in bytes.
/// `real_index_size` must be a multiple of 4 in range [4, 16 GiB].
pub fn encode(check: CheckType, real_index_size: usize) errors.FormatError![FOOTER_SIZE]u8 {
    if ((real_index_size % 4) != 0 or real_index_size < 4) return error.InvalidIndex;
    const backward_size_u64 = (real_index_size / 4) - 1;
    if (backward_size_u64 > std.math.maxInt(u32)) return error.InvalidIndex;
    const backward_size: u32 = @intCast(backward_size_u64);

    var out: [FOOTER_SIZE]u8 = undefined;

    // Bytes 4..8: Backward Size (little-endian)
    std.mem.writeInt(u32, out[4..8], backward_size, .little);

    // Bytes 8..10: Stream Flags
    const flags = stream_flags.encode(check);
    @memcpy(out[8..10], &flags);

    // Bytes 10..12: Footer Magic
    @memcpy(out[10..12], &FOOTER_MAGIC);

    // Bytes 0..4: CRC32 over Backward Size and Stream Flags (out[4..10])
    const crc = crc32.hash(out[4..10]);
    std.mem.writeInt(u32, out[0..4], crc, .little);

    return out;
}

/// Decodes and validates an XZ Stream Footer from a byte slice.
pub fn decode(bytes: []const u8) (errors.FormatError || errors.ChecksumError)!FooterInfo {
    if (bytes.len < FOOTER_SIZE) return error.TruncatedInput;
    const slice = bytes[bytes.len - FOOTER_SIZE ..];

    if (!std.mem.eql(u8, slice[10..12], &FOOTER_MAGIC)) return error.InvalidMagic;

    const stored_crc = std.mem.readInt(u32, slice[0..4], .little);
    const computed_crc = crc32.hash(slice[4..10]);
    if (stored_crc != computed_crc) return error.ChecksumMismatch;

    const backward_size = std.mem.readInt(u32, slice[4..8], .little);
    const flags_bytes: [2]u8 = slice[8..10].*;
    const check = try stream_flags.decode(flags_bytes);
    if (@as(u64, backward_size) >= (@as(u64, std.math.maxInt(usize)) / 4)) {
        return error.InvalidIndex;
    }
    const index_size = (@as(usize, backward_size) + 1) * 4;

    return FooterInfo{
        .check = check,
        .backward_size = backward_size,
        .index_size = index_size,
    };
}

test "stream_footer: encode and decode" {
    const enc = try encode(.crc64, 16);
    const info = try decode(&enc);
    try std.testing.expectEqual(CheckType.crc64, info.check);
    try std.testing.expectEqual(@as(u32, 3), info.backward_size);
    try std.testing.expectEqual(@as(usize, 16), info.index_size);
}
