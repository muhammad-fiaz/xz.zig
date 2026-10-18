//! Stream Header encoding and decoding (Section 2.1.1).
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

pub const HEADER_SIZE: usize = 12;
pub const HEADER_MAGIC = [6]u8{ 0xFD, '7', 'z', 'X', 'Z', 0x00 };

/// Encodes an XZ Stream Header into a 12-byte array.
pub fn encode(check: CheckType) [HEADER_SIZE]u8 {
    var out: [HEADER_SIZE]u8 = undefined;
    @memcpy(out[0..6], &HEADER_MAGIC);
    const flags = stream_flags.encode(check);
    @memcpy(out[6..8], &flags);
    const crc = crc32.hash(&flags);
    std.mem.writeInt(u32, out[8..12], crc, .little);
    return out;
}

/// Decodes and validates an XZ Stream Header from a byte slice.
pub fn decode(bytes: []const u8) (errors.FormatError || errors.ChecksumError)!CheckType {
    if (bytes.len < HEADER_SIZE) return error.TruncatedInput;
    if (!std.mem.eql(u8, bytes[0..6], &HEADER_MAGIC)) return error.InvalidMagic;

    const flags_bytes: [2]u8 = bytes[6..8].*;
    const stored_crc = std.mem.readInt(u32, bytes[8..12], .little);
    const computed_crc = crc32.hash(&flags_bytes);
    if (stored_crc != computed_crc) return error.ChecksumMismatch;

    return stream_flags.decode(flags_bytes);
}

test "stream_header: encode and decode" {
    const hdr = encode(.crc64);
    const check = try decode(&hdr);
    try std.testing.expectEqual(CheckType.crc64, check);
}
