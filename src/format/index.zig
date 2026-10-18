//! Index field encoding and decoding (Section 4).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const vli = @import("vli.zig");
const padding = @import("padding.zig");
const crc32 = @import("../checksum/crc32.zig");

pub const Record = struct {
    unpadded_size: u64,
    uncompressed_size: u64,
};

/// Calculates the total serialized size of the Index (including indicator, records, padding, and CRC32).
pub fn totalSize(records: []const Record) errors.FormatError!usize {
    // Indicator (1) + Number of Records VLI
    var sz: usize = 1 + vli.size(records.len);
    for (records) |r| {
        sz += vli.size(r.unpadded_size);
        sz += vli.size(r.uncompressed_size);
    }
    // Pad to multiple of 4 (before 4-byte CRC32)
    sz += padding.pad4(sz);
    // Plus 4 bytes for CRC32
    sz += 4;
    return sz;
}

/// Encodes the Index field into `dest`. `dest.len` must be at least `totalSize(records)`.
pub fn encode(records: []const Record, dest: []u8) errors.Error!usize {
    const required_size = try totalSize(records);
    if (dest.len < required_size) return error.OutputTooSmall;

    // Index Indicator = 0x00
    dest[0] = 0x00;
    var pos: usize = 1;

    // Number of Records
    pos += try vli.encode(dest[pos..], records.len);

    // List of Records
    for (records) |r| {
        pos += try vli.encode(dest[pos..], r.unpadded_size);
        pos += try vli.encode(dest[pos..], r.uncompressed_size);
    }

    // Index Padding (0-3 null bytes) up to required_size - 4
    while (pos < required_size - 4) {
        dest[pos] = 0x00;
        pos += 1;
    }

    // CRC32 over dest[0 .. required_size - 4]
    const crc = crc32.hash(dest[0 .. required_size - 4]);
    std.mem.writeInt(u32, dest[required_size - 4 .. required_size][0..4], crc, .little);

    return required_size;
}

pub const DecodedIndex = struct {
    records: []Record,
    consumed: usize,
};

/// Decodes and validates an Index field forwards from `src`.
/// Returns the records and the exact number of bytes consumed (including CRC32).
pub fn decodeWithConsumed(allocator: std.mem.Allocator, src: []const u8) (errors.FormatError || errors.ChecksumError || std.mem.Allocator.Error)!DecodedIndex {
    if (src.len < 8) return error.TruncatedInput;
    if (src[0] != 0x00) return error.InvalidIndex; // Index Indicator must be 0x00

    var pos: usize = 1;
    var num_records_u64: u64 = 0;
    pos += try vli.decode(src[pos..], &num_records_u64);

    if (num_records_u64 > 1024 * 1024) return error.InvalidRecordCount; // Sanity limit
    const num_records = @as(usize, @intCast(num_records_u64));

    const records = try allocator.alloc(Record, num_records);
    errdefer allocator.free(records);

    for (0..num_records) |i| {
        if (pos >= src.len) return error.TruncatedInput;
        var unpadded: u64 = 0;
        pos += try vli.decode(src[pos..], &unpadded);
        if (unpadded == 0) return error.InvalidIndex;

        if (pos >= src.len) return error.TruncatedInput;
        var uncompressed: u64 = 0;
        pos += try vli.decode(src[pos..], &uncompressed);

        records[i] = Record{
            .unpadded_size = unpadded,
            .uncompressed_size = uncompressed,
        };
    }

    // Index Padding (0-3 null bytes up to 4-byte boundary)
    const pad_len = padding.pad4(pos);
    if (pos + pad_len + 4 > src.len) return error.TruncatedInput;
    for (src[pos .. pos + pad_len]) |b| {
        if (b != 0x00) return error.InvalidPadding;
    }
    pos += pad_len;

    // CRC32 over src[0..pos]
    const stored_crc = std.mem.readInt(u32, src[pos .. pos + 4][0..4], .little);
    const computed_crc = crc32.hash(src[0..pos]);
    if (stored_crc != computed_crc) return error.ChecksumMismatch;
    pos += 4;

    return DecodedIndex{
        .records = records,
        .consumed = pos,
    };
}

/// Decodes and validates an Index field from exact slice `src`. Returns allocated array of Records.
pub fn decode(allocator: std.mem.Allocator, src: []const u8) (errors.FormatError || errors.ChecksumError || std.mem.Allocator.Error)![]Record {
    if (src.len < 8) return error.TruncatedInput;
    if ((src.len % 4) != 0) return error.InvalidIndex;
    const res = try decodeWithConsumed(allocator, src);
    if (res.consumed != src.len) {
        allocator.free(res.records);
        return error.InvalidIndex;
    }
    return res.records;
}

test "index: encode and decode roundtrip" {
    const records = [_]Record{
        .{ .unpadded_size = 120, .uncompressed_size = 250 },
        .{ .unpadded_size = 80, .uncompressed_size = 150 },
    };

    const sz = try totalSize(&records);
    var buf: [128]u8 = undefined;
    const written = try encode(&records, buf[0..sz]);
    try std.testing.expectEqual(sz, written);

    const decoded = try decode(std.testing.allocator, buf[0..written]);
    defer std.testing.allocator.free(decoded);

    try std.testing.expectEqual(records.len, decoded.len);
    try std.testing.expectEqual(records[0].unpadded_size, decoded[0].unpadded_size);
    try std.testing.expectEqual(records[0].uncompressed_size, decoded[0].uncompressed_size);
    try std.testing.expectEqual(records[1].unpadded_size, decoded[1].unpadded_size);
    try std.testing.expectEqual(records[1].uncompressed_size, decoded[1].uncompressed_size);
}
