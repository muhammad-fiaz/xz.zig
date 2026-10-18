//! Block Header encoding and decoding (Section 3.1).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const vli = @import("vli.zig");
const crc32 = @import("../checksum/crc32.zig");

pub const FilterDesc = struct {
    id: u64,
    properties: []const u8,
};

pub const BlockHeader = struct {
    compressed_size: ?u64 = null,
    uncompressed_size: ?u64 = null,
    filters: []const FilterDesc,

    /// Calculates the total encoded size of the Block Header (must be a multiple of 4, between 8 and 1024 bytes).
    pub fn encodedSize(self: BlockHeader) errors.Error!usize {
        if (self.filters.len == 0 or self.filters.len > 4) return error.TooManyFilters;

        // Header size (1) + Block flags (1)
        var sz: usize = 2;

        if (self.compressed_size) |cs| {
            sz += vli.size(cs);
        }
        if (self.uncompressed_size) |us| {
            sz += vli.size(us);
        }

        for (self.filters) |f| {
            sz += vli.size(f.id);
            sz += vli.size(f.properties.len);
            sz += f.properties.len;
        }

        // Plus 4 bytes for CRC32
        sz += 4;

        // Round up to multiple of 4
        const rem = sz % 4;
        const total = if (rem == 0) sz else sz + (4 - rem);
        if (total < 8 or total > 1024) return error.InvalidHeaderSize;
        return total;
    }

    /// Encodes the Block Header into `dest`. `dest.len` must be at least `self.encodedSize()`.
    pub fn encode(self: BlockHeader, dest: []u8) errors.Error!usize {
        const total_size = try self.encodedSize();
        if (dest.len < total_size) return error.OutputTooSmall;

        const encoded_header_size = (total_size / 4) - 1;
        dest[0] = @as(u8, @intCast(encoded_header_size));

        var flags: u8 = @as(u8, @intCast(self.filters.len - 1));
        if (self.compressed_size != null) flags |= 0x40;
        if (self.uncompressed_size != null) flags |= 0x80;
        dest[1] = flags;

        var pos: usize = 2;

        if (self.compressed_size) |cs| {
            pos += try vli.encode(dest[pos..], cs);
        }
        if (self.uncompressed_size) |us| {
            pos += try vli.encode(dest[pos..], us);
        }

        for (self.filters) |f| {
            pos += try vli.encode(dest[pos..], f.id);
            pos += try vli.encode(dest[pos..], f.properties.len);
            @memcpy(dest[pos .. pos + f.properties.len], f.properties);
            pos += f.properties.len;
        }

        // Header Padding: zero out until total_size - 4
        while (pos < total_size - 4) {
            dest[pos] = 0x00;
            pos += 1;
        }

        // CRC32 over dest[0 .. total_size - 4]
        const crc = crc32.hash(dest[0 .. total_size - 4]);
        std.mem.writeInt(u32, dest[total_size - 4 .. total_size][0..4], crc, .little);

        return total_size;
    }

    /// Decodes a Block Header from `src`.
    /// `filter_buf` and `prop_buf` store decoded filters and their properties.
    pub fn decode(
        src: []const u8,
        filter_buf: *[4]FilterDesc,
        prop_buf: *[4][32]u8,
    ) errors.Error!struct { header: BlockHeader, consumed: usize } {
        if (src.len < 8) return error.TruncatedInput;

        const real_header_size = (@as(usize, src[0]) + 1) * 4;
        if (src.len < real_header_size) return error.TruncatedInput;

        // Verify CRC32
        const stored_crc = std.mem.readInt(u32, src[real_header_size - 4 .. real_header_size][0..4], .little);
        const computed_crc = crc32.hash(src[0 .. real_header_size - 4]);
        if (stored_crc != computed_crc) return error.ChecksumMismatch;

        const flags = src[1];
        if ((flags & 0x3C) != 0) return error.InvalidFlags; // Reserved bits must be 0

        const num_filters = @as(usize, flags & 0x03) + 1;
        const has_compressed_size = (flags & 0x40) != 0;
        const has_uncompressed_size = (flags & 0x80) != 0;

        var pos: usize = 2;
        var comp_size: ?u64 = null;
        var uncomp_size: ?u64 = null;

        if (has_compressed_size) {
            if (pos >= real_header_size - 4) return error.TruncatedInput;
            var val: u64 = 0;
            pos += try vli.decode(src[pos .. real_header_size - 4], &val);
            comp_size = val;
        }

        if (has_uncompressed_size) {
            if (pos >= real_header_size - 4) return error.TruncatedInput;
            var val: u64 = 0;
            pos += try vli.decode(src[pos .. real_header_size - 4], &val);
            uncomp_size = val;
        }

        for (0..num_filters) |i| {
            if (pos >= real_header_size - 4) return error.TruncatedInput;
            var filter_id: u64 = 0;
            pos += try vli.decode(src[pos .. real_header_size - 4], &filter_id);

            if (pos >= real_header_size - 4) return error.TruncatedInput;
            var prop_size: u64 = 0;
            pos += try vli.decode(src[pos .. real_header_size - 4], &prop_size);

            if (prop_size > 32) return error.InvalidFilterProperties;
            const p_sz = @as(usize, @intCast(prop_size));
            if (real_header_size - 4 - pos < p_sz) return error.TruncatedInput;

            @memcpy(prop_buf[i][0..p_sz], src[pos .. pos + p_sz]);
            filter_buf[i] = FilterDesc{
                .id = filter_id,
                .properties = prop_buf[i][0..p_sz],
            };
            pos += p_sz;
        }

        // Validate Header Padding: all bytes up to real_header_size - 4 must be 0x00
        while (pos < real_header_size - 4) {
            if (src[pos] != 0x00) return error.InvalidPadding;
            pos += 1;
        }

        return .{
            .header = BlockHeader{
                .compressed_size = comp_size,
                .uncompressed_size = uncomp_size,
                .filters = filter_buf[0..num_filters],
            },
            .consumed = real_header_size,
        };
    }
};

test "block_header: encode and decode roundtrip" {
    var filter_buf: [4]FilterDesc = undefined;
    var prop_buf: [4][32]u8 = undefined;

    const props = [_]u8{0x10}; // 1 MiB dict size
    const filters = [_]FilterDesc{
        .{ .id = 0x21, .properties = &props },
    };

    const original = BlockHeader{
        .compressed_size = 1234,
        .uncompressed_size = 5678,
        .filters = &filters,
    };

    var encoded: [128]u8 = undefined;
    const len = try original.encode(&encoded);

    const res = try BlockHeader.decode(encoded[0..len], &filter_buf, &prop_buf);
    try std.testing.expectEqual(len, res.consumed);
    try std.testing.expectEqual(@as(?u64, 1234), res.header.compressed_size);
    try std.testing.expectEqual(@as(?u64, 5678), res.header.uncompressed_size);
    try std.testing.expectEqual(@as(usize, 1), res.header.filters.len);
    try std.testing.expectEqual(@as(u64, 0x21), res.header.filters[0].id);
    try std.testing.expectEqualSlices(u8, &props, res.header.filters[0].properties);
}
