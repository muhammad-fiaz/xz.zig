//! XZ Block encoder (Section 3).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const options_mod = @import("../options.zig");
const CheckType = options_mod.CheckType;
const CompressOptions = options_mod.CompressOptions;

const block_header = @import("../format/block_header.zig");
const BlockHeader = block_header.BlockHeader;
const FilterDesc = block_header.FilterDesc;
const index_mod = @import("../format/index.zig");
const Record = index_mod.Record;
const padding = @import("../format/padding.zig");

const crc32 = @import("../checksum/crc32.zig");
const crc64 = @import("../checksum/crc64.zig");
const sha256 = @import("../checksum/sha256.zig");

const lzma2_filter = @import("../filters/lzma2.zig");
const filter_mod = @import("../filters/filter.zig");
const bcj = @import("../filters/bcj.zig");
const delta = @import("../filters/delta.zig");

pub const BlockResult = struct {
    data: []u8,
    record: Record,
};

/// Encodes an uncompressed byte slice into an XZ Block using the configured options and filters.
pub fn encodeBlock(allocator: std.mem.Allocator, src: []const u8, options: CompressOptions) !BlockResult {
    // 1. Calculate Check over the original uncompressed data
    var check_buf: [32]u8 = undefined;
    const check_size = options.check.checkSize();
    switch (options.check) {
        .none => {},
        .crc32 => {
            const c = crc32.hash(src);
            std.mem.writeInt(u32, check_buf[0..4], c, .little);
        },
        .crc64 => {
            const c = crc64.hash(src);
            std.mem.writeInt(u64, check_buf[0..8], c, .little);
        },
        .sha256 => {
            const d = sha256.hash(src);
            @memcpy(check_buf[0..32], &d);
        },
        else => return error.UnsupportedCheck,
    }

    // 2. Prepare filter pipeline
    var filter_descs: [4]FilterDesc = undefined;
    var filter_props: [4][32]u8 = undefined;
    var num_filters: usize = 0;

    var filtered_data: []u8 = undefined;
    var owns_filtered = false;
    defer {
        if (owns_filtered) allocator.free(filtered_data);
    }

    // Optional Delta filter
    if (options.delta_distance) |dist| {
        filtered_data = try allocator.dupe(u8, src);
        owns_filtered = true;
        var st = delta.State.init(dist);
        st.encode(filtered_data);

        filter_props[num_filters][0] = dist;
        filter_descs[num_filters] = FilterDesc{
            .id = filter_mod.FILTER_DELTA,
            .properties = filter_props[num_filters][0..1],
        };
        num_filters += 1;
    }

    // Optional x86 BCJ filter
    if (options.bcj_x86) {
        if (!owns_filtered) {
            filtered_data = try allocator.dupe(u8, src);
            owns_filtered = true;
        }
        var st = bcj.X86State{};
        _ = st.code(0, true, filtered_data);

        filter_descs[num_filters] = FilterDesc{
            .id = filter_mod.FILTER_X86_BCJ,
            .properties = &[_]u8{},
        };
        num_filters += 1;
    }

    const payload_to_compress = if (owns_filtered) filtered_data else src;

    // 3. Compress payload using LZMA2 from lzma2.zig
    const lzma2_opts = lzma2_filter.lzma2.Options{
        .level = options.level,
        .dict_size = options.dict_size,
    };
    const compressed_data = try lzma2_filter.compress(allocator, payload_to_compress, lzma2_opts);
    defer allocator.free(compressed_data);

    // 4. Set up LZMA2 FilterDesc
    const actual_dict = options.dict_size orelse lzma2_opts.getDictSize();
    const prop_byte = try lzma2_filter.dictSizeToProp(actual_dict);
    filter_props[num_filters][0] = prop_byte;
    filter_descs[num_filters] = FilterDesc{
        .id = filter_mod.FILTER_LZMA2,
        .properties = filter_props[num_filters][0..1],
    };
    num_filters += 1;

    // 5. Build Block Header
    const b_hdr = BlockHeader{
        .compressed_size = compressed_data.len,
        .uncompressed_size = src.len,
        .filters = filter_descs[0..num_filters],
    };
    const header_size = try b_hdr.encodedSize();

    // 6. Calculate total block size
    const block_pad = padding.pad4(compressed_data.len);
    const unpadded_size = header_size + compressed_data.len + check_size;
    const total_block_size = unpadded_size + block_pad;

    const block_bytes = try allocator.alloc(u8, total_block_size);
    errdefer allocator.free(block_bytes);

    // Serialize Header
    _ = try b_hdr.encode(block_bytes[0..header_size]);

    // Serialize Compressed Data
    var pos = header_size;
    @memcpy(block_bytes[pos .. pos + compressed_data.len], compressed_data);
    pos += compressed_data.len;

    // Serialize Block Padding (null bytes)
    for (0..block_pad) |_| {
        block_bytes[pos] = 0x00;
        pos += 1;
    }

    // Serialize Check
    if (check_size > 0) {
        @memcpy(block_bytes[pos .. pos + check_size], check_buf[0..check_size]);
        pos += check_size;
    }

    return BlockResult{
        .data = block_bytes,
        .record = Record{
            .unpadded_size = unpadded_size,
            .uncompressed_size = src.len,
        },
    };
}
