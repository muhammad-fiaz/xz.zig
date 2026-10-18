//! XZ Stream decompressor (Section 2).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const options_mod = @import("../options.zig");
const DecompressOptions = options_mod.DecompressOptions;

const stream_header = @import("../format/stream_header.zig");
const stream_footer = @import("../format/stream_footer.zig");
const block_decompress = @import("block.zig");
const index_mod = @import("../format/index.zig");

/// Decompresses an entire XZ stream (including concatenated streams and stream padding) into an allocated buffer.
pub fn decompress(allocator: std.mem.Allocator, src: []const u8, options: DecompressOptions) ![]u8 {
    if (src.len < 32) return error.TruncatedInput;

    var out_list: std.ArrayList(u8) = .empty;
    errdefer out_list.deinit(allocator);

    var pos: usize = 0;

    while (pos < src.len) {
        // Handle Stream Padding (zero or more 4-byte null words)
        while (pos + 4 <= src.len and std.mem.eql(u8, src[pos .. pos + 4], &[_]u8{ 0, 0, 0, 0 })) {
            pos += 4;
        }

        if (pos == src.len) {
            // Clean EOF reached after Stream Padding
            break;
        }

        if (src.len - pos < 32) return error.TruncatedInput;

        // 1. Decode and validate Stream Header (12 bytes)
        const check = try stream_header.decode(src[pos .. pos + 12]);
        pos += 12;

        // 2. Decode Blocks until 0x00 (Index Indicator)
        var records_list: std.ArrayList(index_mod.Record) = .empty;
        defer records_list.deinit(allocator);

        while (pos < src.len) {
            const first_byte = src[pos];
            if (first_byte == 0x00) {
                // Index Indicator reached!
                break;
            }

            const block_res = try block_decompress.decodeBlock(allocator, src[pos..], check, options);
            defer allocator.free(block_res.data);

            const max_output = options.max_output_size orelse std.math.maxInt(usize);
            if (max_output - out_list.items.len < block_res.data.len) {
                return error.ExceededOutputLimit;
            }

            try out_list.appendSlice(allocator, block_res.data);
            try records_list.append(allocator, .{
                .unpadded_size = block_res.unpadded_size,
                .uncompressed_size = block_res.uncompressed_size,
            });

            pos += block_res.consumed;
        }

        if (pos >= src.len or src[pos] != 0x00) return error.TruncatedInput;

        // 3. Decode Index
        const index_res = try index_mod.decodeWithConsumed(allocator, src[pos..]);
        defer allocator.free(index_res.records);
        pos += index_res.consumed;

        // Verify index records match decoded blocks
        if (index_res.records.len != records_list.items.len) {
            return error.SizeMismatch;
        }
        for (index_res.records, records_list.items) |idx_rec, blk_rec| {
            if (idx_rec.unpadded_size != blk_rec.unpadded_size or
                idx_rec.uncompressed_size != blk_rec.uncompressed_size)
            {
                return error.SizeMismatch;
            }
        }

        // 4. Decode Stream Footer (12 bytes)
        if (src.len - pos < 12) return error.TruncatedInput;
        const footer = try stream_footer.decode(src[pos .. pos + 12]);
        pos += 12;

        if (footer.check != check) return error.StreamFlagsMismatch;
        if (footer.index_size != index_res.consumed) return error.BackwardSizeMismatch;
    }

    return out_list.toOwnedSlice(allocator);
}

/// Decompresses an entire XZ stream into a caller-provided destination slice `dest`.
pub fn decompressInto(src: []const u8, dest: []u8, options: DecompressOptions) !usize {
    const allocator = std.heap.smp_allocator;
    var opts = options;
    if (opts.max_output_size == null or opts.max_output_size.? > dest.len) {
        opts.max_output_size = dest.len;
    }
    const result = decompress(allocator, src, opts) catch |err| {
        if (err == error.ExceededOutputLimit) return error.OutputTooSmall;
        return err;
    };
    defer allocator.free(result);

    if (dest.len < result.len) return error.OutputTooSmall;
    @memcpy(dest[0..result.len], result);
    return result.len;
}
