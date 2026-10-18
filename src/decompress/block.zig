//! XZ Block decoder (Section 3).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const options_mod = @import("../options.zig");
const CheckType = options_mod.CheckType;
const DecompressOptions = options_mod.DecompressOptions;

const block_header = @import("../format/block_header.zig");
const BlockHeader = block_header.BlockHeader;
const FilterDesc = block_header.FilterDesc;
const padding = @import("../format/padding.zig");

const crc32 = @import("../checksum/crc32.zig");
const crc64 = @import("../checksum/crc64.zig");
const sha256 = @import("../checksum/sha256.zig");

const lzma2_filter = @import("../filters/lzma2.zig");
const filter_mod = @import("../filters/filter.zig");
const bcj = @import("../filters/bcj.zig");
const delta = @import("../filters/delta.zig");

pub const DecodedBlock = struct {
    data: []u8,
    consumed: usize,
    unpadded_size: u64,
    uncompressed_size: u64,
};

/// Decodes an XZ Block from `src`.
pub fn decodeBlock(
    allocator: std.mem.Allocator,
    src: []const u8,
    check: CheckType,
    options: DecompressOptions,
) !DecodedBlock {
    var filter_buf: [4]FilterDesc = undefined;
    var prop_buf: [4][32]u8 = undefined;

    // 1. Decode and validate Block Header
    const hdr_res = try BlockHeader.decode(src, &filter_buf, &prop_buf);
    const header = hdr_res.header;
    const header_size = hdr_res.consumed;

    if (header.filters.len == 0 or header.filters.len > 4) return error.TooManyFilters;

    // Last filter MUST be LZMA2
    const last_filter = header.filters[header.filters.len - 1];
    if (last_filter.id != filter_mod.FILTER_LZMA2) return error.InvalidFilterOrder;
    if (last_filter.properties.len < 1) return error.InvalidFilterProperties;

    // Check LZMA2 dictionary size
    const dict_size = try lzma2_filter.propToDictSize(last_filter.properties[0]);
    if (dict_size > options.getEffectiveMemlimit()) return error.ExceededMemoryLimit;

    // Validate non-last filters
    for (header.filters[0 .. header.filters.len - 1]) |f| {
        if (!filter_mod.isSupportedFilter(f.id)) return error.UnsupportedFilter;
    }

    // 2. Identify Compressed Data slice
    const check_size = check.checkSize();
    var compressed_slice: []const u8 = undefined;
    var block_padding_len: usize = 0;
    var consumed_total: usize = 0;

    var cs_usize: usize = 0;
    if (header.compressed_size) |cs| {
        cs_usize = @as(usize, @intCast(cs));
    } else {
        // Without explicit compressed size in header, parse raw LZMA2 chunk headers until control byte 0x00
        var p = header_size;
        var found_end = false;
        while (p < src.len) {
            const control = src[p];
            p += 1;
            if (control == 0x00) {
                found_end = true;
                break;
            } else if ((control & 0x80) == 0) {
                if (control > 2) return error.CorruptData;
                if (p + 2 > src.len) return error.TruncatedInput;
                const chunk_size = (@as(usize, src[p]) << 8 | @as(usize, src[p + 1])) + 1;
                p += 2 + chunk_size;
            } else {
                if (p + 4 > src.len) return error.TruncatedInput;
                const mode: u2 = @truncate((control >> 5) & 3);
                const pack_size = (@as(usize, src[p + 2]) << 8 | @as(usize, src[p + 3])) + 1;
                const prop_len: usize = if (mode >= 2) 1 else 0;
                p += 4 + prop_len + pack_size;
            }
        }
        if (!found_end) return error.TruncatedInput;
        cs_usize = p - header_size;
    }

    block_padding_len = padding.pad4(cs_usize);
    const expected_block_len = header_size + cs_usize + block_padding_len + check_size;
    if (src.len < expected_block_len) return error.TruncatedInput;

    compressed_slice = src[header_size .. header_size + cs_usize];

    // Validate Block Padding
    const pad_slice = src[header_size + cs_usize .. header_size + cs_usize + block_padding_len];
    try padding.validatePadding(pad_slice);

    consumed_total = expected_block_len;

    // 3. Decompress LZMA2 payload using lzma2.zig
    const lzma2_decomp_opts = lzma2_filter.lzma2.DecompressOptions{
        .dict_size_limit = dict_size,
        .max_output_size = options.max_output_size orelse std.math.maxInt(usize),
    };
    const decompressed = try lzma2_filter.decompress(allocator, compressed_slice, lzma2_decomp_opts);
    errdefer allocator.free(decompressed);

    // If uncompressed size is declared in header, verify match
    if (header.uncompressed_size) |us| {
        if (decompressed.len != us) return error.SizeMismatch;
    }

    // 4. Reverse non-last filters in reverse order
    var i: usize = header.filters.len - 1;
    while (i > 0) {
        i -= 1;
        const f = header.filters[i];
        if (f.id == filter_mod.FILTER_DELTA) {
            if (f.properties.len < 1) return error.InvalidFilterProperties;
            var st = delta.State.init(f.properties[0]);
            st.decode(decompressed);
        } else if (f.id == filter_mod.FILTER_X86_BCJ) {
            var st = bcj.X86State{};
            _ = st.code(0, false, decompressed);
        }
    }

    // 5. Verify Check
    if (options.verify_checksum and check_size > 0) {
        const stored_check = src[consumed_total - check_size .. consumed_total];
        switch (check) {
            .none => {},
            .crc32 => {
                const computed = crc32.hash(decompressed);
                const stored = std.mem.readInt(u32, stored_check[0..4], .little);
                if (computed != stored) return error.ChecksumMismatch;
            },
            .crc64 => {
                const computed = crc64.hash(decompressed);
                const stored = std.mem.readInt(u64, stored_check[0..8], .little);
                if (computed != stored) return error.ChecksumMismatch;
            },
            .sha256 => {
                const computed = sha256.hash(decompressed);
                if (!std.mem.eql(u8, &computed, stored_check[0..32])) return error.ChecksumMismatch;
            },
            else => return error.UnsupportedCheck,
        }
    }

    const unpadded_size = header_size + compressed_slice.len + check_size;

    return DecodedBlock{
        .data = decompressed,
        .consumed = consumed_total,
        .unpadded_size = unpadded_size,
        .uncompressed_size = decompressed.len,
    };
}
