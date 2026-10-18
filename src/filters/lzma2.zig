//! LZMA2 filter integration via lzma2.zig library.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
pub const lzma2 = @import("lzma2");
const errors = @import("../errors.zig");

/// Converts a dictionary size in bytes to a 1-byte XZ LZMA2 property byte.
pub fn dictSizeToProp(dict_size: u32) !u8 {
    return lzma2.dictSizeToProp(dict_size);
}

/// Decodes an XZ LZMA2 property byte into a dictionary size in bytes.
pub fn propToDictSize(prop: u8) errors.FilterError!u32 {
    const sz = lzma2.propToDictSize(prop) catch return error.InvalidFilterProperties;
    if (sz == 0) return error.InvalidFilterProperties;
    return sz;
}

/// Encodes uncompressed data into raw LZMA2 format using the public lzma2.zig API.
pub fn compress(allocator: std.mem.Allocator, src: []const u8, options: lzma2.Options) ![]u8 {
    return lzma2.compress(allocator, src, options);
}

/// Encodes uncompressed data into caller-provided buffer `dest`.
pub fn compressInto(src: []const u8, dest: []u8, options: lzma2.Options) !usize {
    return lzma2.compressInto(src, dest, options);
}

/// Decodes raw LZMA2 data using the public lzma2.zig API.
pub fn decompress(allocator: std.mem.Allocator, src: []const u8, options: lzma2.DecompressOptions) ![]u8 {
    return lzma2.decompress(allocator, src, options) catch |err| {
        if (err == error.ExceededSizeLimit) return error.ExceededOutputLimit;
        return err;
    };
}

/// Decodes raw LZMA2 data into caller-provided buffer `dest`.
pub fn decompressInto(src: []const u8, dest: []u8, options: lzma2.DecompressOptions) !usize {
    return lzma2.decompressInto(src, dest, options) catch |err| {
        if (err == error.ExceededSizeLimit) return error.ExceededOutputLimit;
        return err;
    };
}
