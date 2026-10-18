//! XZ Stream compressor (Section 2).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const options_mod = @import("../options.zig");
const CompressOptions = options_mod.CompressOptions;

const stream_header = @import("../format/stream_header.zig");
const stream_footer = @import("../format/stream_footer.zig");
const block_compress = @import("block.zig");
const index_mod = @import("../format/index.zig");
const Record = index_mod.Record;
const lzma2_filter = @import("../filters/lzma2.zig");

/// Calculates an upper bound on compressed buffer size for worst-case expansion.
pub fn maxCompressedSize(src_len: usize) usize {
    // Header (12) + Block Header (64 max) + lzma2 max + Pad (4) + Check (32) + Index (64) + Footer (12)
    const lzma2_max = lzma2_filter.lzma2.maxCompressedSize(src_len);
    return 12 + 64 + lzma2_max + 4 + 32 + 64 + 12;
}

/// Compresses `src` into a complete XZ stream, returning an allocated slice.
pub fn compress(allocator: std.mem.Allocator, src: []const u8, options: CompressOptions) ![]u8 {
    // 1. Encode Stream Header (12 bytes)
    const header_bytes = stream_header.encode(options.check);

    // For empty input (0 bytes), emit an empty stream with zero blocks as permitted
    // by Section 2.1 of the XZ specification and matching canonical XZ Utils behavior.
    if (src.len == 0) {
        const records = [_]Record{};
        const index_size = try index_mod.totalSize(&records);
        const index_buf = try allocator.alloc(u8, index_size);
        defer allocator.free(index_buf);
        _ = try index_mod.encode(&records, index_buf);

        const footer_bytes = try stream_footer.encode(options.check, index_size);

        const total_stream_size = header_bytes.len + index_size + footer_bytes.len;
        const stream = try allocator.alloc(u8, total_stream_size);
        errdefer allocator.free(stream);

        var pos: usize = 0;
        @memcpy(stream[pos .. pos + header_bytes.len], &header_bytes);
        pos += header_bytes.len;

        @memcpy(stream[pos .. pos + index_size], index_buf);
        pos += index_size;

        @memcpy(stream[pos .. pos + footer_bytes.len], &footer_bytes);
        return stream;
    }

    // 2. Encode Block (data + check + padding)
    const block_res = try block_compress.encodeBlock(allocator, src, options);
    defer allocator.free(block_res.data);

    // 3. Encode Index
    const records = [_]Record{block_res.record};
    const index_size = try index_mod.totalSize(&records);
    const index_buf = try allocator.alloc(u8, index_size);
    defer allocator.free(index_buf);
    _ = try index_mod.encode(&records, index_buf);

    // 4. Encode Stream Footer (12 bytes)
    const footer_bytes = try stream_footer.encode(options.check, index_size);

    // 5. Assemble final stream
    const total_stream_size = header_bytes.len + block_res.data.len + index_size + footer_bytes.len;
    const stream = try allocator.alloc(u8, total_stream_size);
    errdefer allocator.free(stream);

    var pos: usize = 0;
    @memcpy(stream[pos .. pos + header_bytes.len], &header_bytes);
    pos += header_bytes.len;

    @memcpy(stream[pos .. pos + block_res.data.len], block_res.data);
    pos += block_res.data.len;

    @memcpy(stream[pos .. pos + index_size], index_buf);
    pos += index_size;

    @memcpy(stream[pos .. pos + footer_bytes.len], &footer_bytes);
    pos += footer_bytes.len;

    return stream;
}

/// Compresses `src` into a caller-provided buffer `dest`. Returns written size.
pub fn compressInto(src: []const u8, dest: []u8, options: CompressOptions) !usize {
    const allocator = std.heap.smp_allocator;
    const result = try compress(allocator, src, options);
    defer allocator.free(result);

    if (dest.len < result.len) return error.OutputTooSmall;
    @memcpy(dest[0..result.len], result);
    return result.len;
}
