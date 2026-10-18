//! xz.zig — Modern Native Zig XZ Container Compression Library
//!
//! Implementation of the XZ Container File Format (Version 1.0.4)
//! using lzma2.zig as its underlying LZMA2 codec dependency.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");

// Library version
pub const version = "0.0.1";

// Re-export dependency
pub const lzma2 = @import("lzma2");

// Submodules
pub const errors = @import("errors.zig");
pub const options = @import("options.zig");
pub const checksum = struct {
    pub const crc32 = @import("checksum/crc32.zig");
    pub const crc64 = @import("checksum/crc64.zig");
    pub const sha256 = @import("checksum/sha256.zig");
};
pub const format = struct {
    pub const vli = @import("format/vli.zig");
    pub const padding = @import("format/padding.zig");
    pub const stream_flags = @import("format/stream_flags.zig");
    pub const stream_header = @import("format/stream_header.zig");
    pub const stream_footer = @import("format/stream_footer.zig");
    pub const block_header = @import("format/block_header.zig");
    pub const index = @import("format/index.zig");
};
pub const filters = struct {
    pub const filter = @import("filters/filter.zig");
    pub const lzma2_filter = @import("filters/lzma2.zig");
    pub const delta = @import("filters/delta.zig");
    pub const bcj = @import("filters/bcj.zig");
};

pub const compress_mod = @import("compress/stream.zig");
pub const decompress_mod = @import("decompress/stream.zig");
pub const compress_streaming = @import("compress/streaming.zig");
pub const decompress_streaming = @import("decompress/streaming.zig");

// High-level types
pub const CheckType = options.CheckType;
pub const CompressOptions = options.CompressOptions;
pub const DecompressOptions = options.DecompressOptions;
pub const Error = errors.Error;
pub const CompressError = errors.CompressError;
pub const DecompressError = errors.DecompressError;

// Convenient one-shot APIs
pub const compress = compress_mod.compress;
pub const compressInto = compress_mod.compressInto;
pub const decompress = decompress_mod.decompress;
pub const decompressInto = decompress_mod.decompressInto;
pub const maxCompressedSize = compress_mod.maxCompressedSize;

// Streaming APIs
pub const compressStream = compress_streaming.compressStream;
pub const decompressStream = decompress_streaming.decompressStream;
pub const StreamingCompressor = compress_streaming.StreamingCompressor;

// Checksum convenience functions
pub const crc32 = checksum.crc32.hash;
pub const crc64 = checksum.crc64.hash;
pub const sha256 = checksum.sha256.hash;

/// Inspects whether the provided byte slice begins with the valid XZ header magic bytes (FD 37 7A 58 5A 00).
pub fn isXzStream(data: []const u8) bool {
    if (data.len < format.stream_header.HEADER_MAGIC.len) return false;
    return std.mem.eql(u8, data[0..format.stream_header.HEADER_MAGIC.len], &format.stream_header.HEADER_MAGIC);
}

test {
    _ = @import("checksum/crc32.zig");
    _ = @import("checksum/crc64.zig");
    _ = @import("checksum/sha256.zig");
    _ = @import("format/vli.zig");
    _ = @import("format/padding.zig");
    _ = @import("format/stream_flags.zig");
    _ = @import("format/stream_header.zig");
    _ = @import("format/stream_footer.zig");
    _ = @import("format/block_header.zig");
    _ = @import("format/index.zig");
    _ = @import("filters/delta.zig");
    _ = @import("filters/bcj.zig");
}

test "xz: basic roundtrip all check types" {
    const checks = [_]CheckType{ .none, .crc32, .crc64, .sha256 };
    const original_msg = "The quick brown fox jumps over the lazy dog. Standard XZ container verification test.";

    for (checks) |c| {
        const compressed = try compress(std.testing.allocator, original_msg, .{ .check = c });
        defer std.testing.allocator.free(compressed);

        try std.testing.expect(isXzStream(compressed));

        const decompressed = try decompress(std.testing.allocator, compressed, .{});
        defer std.testing.allocator.free(decompressed);

        try std.testing.expectEqualStrings(original_msg, decompressed);
    }
}

test "xz: caller buffer roundtrip" {
    const original = "Zero-allocation stack buffer test for xz.zig!";
    var comp_buf: [512]u8 = undefined;
    var decomp_buf: [512]u8 = undefined;

    const comp_len = try compressInto(original, &comp_buf, .{});
    const decomp_len = try decompressInto(comp_buf[0..comp_len], &decomp_buf, .{});

    try std.testing.expectEqualStrings(original, decomp_buf[0..decomp_len]);
}

test "xz: empty input roundtrip" {
    const empty: []const u8 = "";
    const compressed = try compress(std.testing.allocator, empty, .{});
    defer std.testing.allocator.free(compressed);

    try std.testing.expect(isXzStream(compressed));
    // Exact 32 bytes parity: 12 B header + 0 B blocks + 8 B index + 12 B footer
    try std.testing.expectEqual(@as(usize, 32), compressed.len);

    const decompressed = try decompress(std.testing.allocator, compressed, .{});
    defer std.testing.allocator.free(decompressed);

    try std.testing.expectEqualStrings(empty, decompressed);

    // Also verify caller-buffer empty compression
    var buf: [64]u8 = undefined;
    const written = try compressInto(empty, &buf, .{});
    try std.testing.expectEqual(@as(usize, 32), written);

    // Also verify streaming empty compression
    var comp_list: std.ArrayList(u8) = .empty;
    defer comp_list.deinit(std.testing.allocator);
    var comp_w = struct {
        list: *std.ArrayList(u8),
        alloc: std.mem.Allocator,
        pub fn writeAll(self: *@This(), bytes: []const u8) !void {
            try self.list.appendSlice(self.alloc, bytes);
        }
    }{ .list = &comp_list, .alloc = std.testing.allocator };

    var scomp = StreamingCompressor.init(std.testing.allocator, .{});
    defer scomp.deinit();
    try scomp.finish(&comp_w);
    try std.testing.expectEqual(@as(usize, 32), comp_list.items.len);
    try std.testing.expectEqualSlices(u8, compressed, comp_list.items);
}

test "xz: streaming pipeline roundtrip" {
    const input = "Incremental streaming pipeline roundtrip test for xz.zig!";
    var in_r = struct {
        slice: []const u8,
        pos: usize = 0,
        pub fn read(self: *@This(), buf: []u8) !usize {
            if (self.pos >= self.slice.len) return 0;
            const n = @min(self.slice.len - self.pos, buf.len);
            @memcpy(buf[0..n], self.slice[self.pos .. self.pos + n]);
            self.pos += n;
            return n;
        }
    }{ .slice = input };

    var comp_list: std.ArrayList(u8) = .empty;
    defer comp_list.deinit(std.testing.allocator);
    var comp_w = struct {
        list: *std.ArrayList(u8),
        alloc: std.mem.Allocator,
        pub fn writeAll(self: *@This(), bytes: []const u8) !void {
            try self.list.appendSlice(self.alloc, bytes);
        }
    }{ .list = &comp_list, .alloc = std.testing.allocator };

    try compressStream(&in_r, &comp_w, .{});

    var comp_r = struct {
        slice: []const u8,
        pos: usize = 0,
        pub fn read(self: *@This(), buf: []u8) !usize {
            if (self.pos >= self.slice.len) return 0;
            const n = @min(self.slice.len - self.pos, buf.len);
            @memcpy(buf[0..n], self.slice[self.pos .. self.pos + n]);
            self.pos += n;
            return n;
        }
    }{ .slice = comp_list.items };

    var out_list: std.ArrayList(u8) = .empty;
    defer out_list.deinit(std.testing.allocator);
    var out_w = struct {
        list: *std.ArrayList(u8),
        alloc: std.mem.Allocator,
        pub fn writeAll(self: *@This(), bytes: []const u8) !void {
            try self.list.appendSlice(self.alloc, bytes);
        }
    }{ .list = &out_list, .alloc = std.testing.allocator };

    try decompressStream(&comp_r, &out_w, .{});
    try std.testing.expectEqualStrings(input, out_list.items);
}

test "xz: multi-block streaming roundtrip" {
    const input = "Multi-block streaming chunk test: block 1! block 2! block 3! block 4! block 5!";
    var comp_list: std.ArrayList(u8) = .empty;
    defer comp_list.deinit(std.testing.allocator);
    var comp_w = struct {
        list: *std.ArrayList(u8),
        alloc: std.mem.Allocator,
        pub fn writeAll(self: *@This(), bytes: []const u8) !void {
            try self.list.appendSlice(self.alloc, bytes);
        }
    }{ .list = &comp_list, .alloc = std.testing.allocator };

    var scomp = StreamingCompressor.init(std.testing.allocator, .{});
    scomp.block_size = 16;
    defer scomp.deinit();

    try scomp.write(&comp_w, input);
    try scomp.finish(&comp_w);

    try std.testing.expect(scomp.records.items.len > 1);

    const decomp_oneshot = try decompress(std.testing.allocator, comp_list.items, .{});
    defer std.testing.allocator.free(decomp_oneshot);
    try std.testing.expectEqualStrings(input, decomp_oneshot);

    var comp_r = struct {
        slice: []const u8,
        pos: usize = 0,
        pub fn read(self: *@This(), buf: []u8) !usize {
            if (self.pos >= self.slice.len) return 0;
            const n = @min(self.slice.len - self.pos, buf.len);
            @memcpy(buf[0..n], self.slice[self.pos .. self.pos + n]);
            self.pos += n;
            return n;
        }
    }{ .slice = comp_list.items };

    var out_list: std.ArrayList(u8) = .empty;
    defer out_list.deinit(std.testing.allocator);
    var out_w = struct {
        list: *std.ArrayList(u8),
        alloc: std.mem.Allocator,
        pub fn writeAll(self: *@This(), bytes: []const u8) !void {
            try self.list.appendSlice(self.alloc, bytes);
        }
    }{ .list = &out_list, .alloc = std.testing.allocator };

    try decompressStream(&comp_r, &out_w, .{});
    try std.testing.expectEqualStrings(input, out_list.items);
}

test "xz: max_output_size limit enforcement" {
    const input = "Safety limit enforcement test for decompressed data volume.";
    const compressed = try compress(std.testing.allocator, input, .{});
    defer std.testing.allocator.free(compressed);

    const err = decompress(std.testing.allocator, compressed, .{ .max_output_size = 10 });
    try std.testing.expectError(error.ExceededOutputLimit, err);
}

test "xz: concatenated streams and stream padding" {
    const part1 = "First concatenated XZ stream chunk. ";
    const part2 = "Second concatenated XZ stream chunk with independent filter and check!";

    const comp1 = try compress(std.testing.allocator, part1, .{ .check = .crc32 });
    defer std.testing.allocator.free(comp1);

    const comp2 = try compress(std.testing.allocator, part2, .{ .check = .crc64 });
    defer std.testing.allocator.free(comp2);

    // 1. Direct concatenation: comp1 ++ comp2
    var concat_direct: std.ArrayList(u8) = .empty;
    defer concat_direct.deinit(std.testing.allocator);
    try concat_direct.appendSlice(std.testing.allocator, comp1);
    try concat_direct.appendSlice(std.testing.allocator, comp2);

    const decomp_direct = try decompress(std.testing.allocator, concat_direct.items, .{});
    defer std.testing.allocator.free(decomp_direct);
    try std.testing.expectEqualStrings("First concatenated XZ stream chunk. Second concatenated XZ stream chunk with independent filter and check!", decomp_direct);

    // 2. Concatenation with Stream Padding (8 null bytes between streams, 4 null bytes trailing)
    var concat_padded: std.ArrayList(u8) = .empty;
    defer concat_padded.deinit(std.testing.allocator);
    try concat_padded.appendSlice(std.testing.allocator, comp1);
    try concat_padded.appendSlice(std.testing.allocator, &[_]u8{ 0, 0, 0, 0, 0, 0, 0, 0 }); // 8 bytes padding
    try concat_padded.appendSlice(std.testing.allocator, comp2);
    try concat_padded.appendSlice(std.testing.allocator, &[_]u8{ 0, 0, 0, 0 }); // 4 bytes trailing padding

    const decomp_padded = try decompress(std.testing.allocator, concat_padded.items, .{});
    defer std.testing.allocator.free(decomp_padded);
    try std.testing.expectEqualStrings("First concatenated XZ stream chunk. Second concatenated XZ stream chunk with independent filter and check!", decomp_padded);

    // 3. Streaming pipeline verification of concatenated padded streams
    var stream_r = struct {
        slice: []const u8,
        pos: usize = 0,
        pub fn read(self: *@This(), buf: []u8) !usize {
            if (self.pos >= self.slice.len) return 0;
            const n = @min(buf.len, self.slice.len - self.pos);
            @memcpy(buf[0..n], self.slice[self.pos .. self.pos + n]);
            self.pos += n;
            return n;
        }
    }{ .slice = concat_padded.items };

    var stream_out: std.ArrayList(u8) = .empty;
    defer stream_out.deinit(std.testing.allocator);
    var stream_w = struct {
        list: *std.ArrayList(u8),
        alloc: std.mem.Allocator,
        pub fn writeAll(self: *@This(), bytes: []const u8) !void {
            try self.list.appendSlice(self.alloc, bytes);
        }
    }{ .list = &stream_out, .alloc = std.testing.allocator };

    try decompressStream(&stream_r, &stream_w, .{});
    try std.testing.expectEqualStrings("First concatenated XZ stream chunk. Second concatenated XZ stream chunk with independent filter and check!", stream_out.items);
}

test "xz: error handling corrupted magic and bad checksum" {
    const input = "Validation of corrupted container error paths.";
    const compressed = try compress(std.testing.allocator, input, .{});
    defer std.testing.allocator.free(compressed);

    var bad_magic: [256]u8 = undefined;
    @memcpy(bad_magic[0..compressed.len], compressed);
    bad_magic[0] = 0x00;
    try std.testing.expectError(error.InvalidMagic, decompress(std.testing.allocator, bad_magic[0..compressed.len], .{}));

    var bad_payload: [256]u8 = undefined;
    @memcpy(bad_payload[0..compressed.len], compressed);
    bad_payload[20] ^= 0x55;
    try std.testing.expectError(error.ChecksumMismatch, decompress(std.testing.allocator, bad_payload[0..compressed.len], .{}));
}

test "architecture: width-sensitive arithmetic and VLI boundary regression tests" {
    const vli = format.vli;
    const stream_footer = format.stream_footer;
    const index = format.index;

    // 1. VLI boundary values
    const vli_boundaries = [_]u64{
        0,
        1,
        127,
        128,
        16383,
        16384,
        2097151,
        2097152,
        0x7FFFFFFF,
        0xFFFFFFFF,
        0x7FFFFFFFFFFFFFFF, // VLI_MAX
    };
    var vli_buf: [16]u8 = undefined;
    for (vli_boundaries) |val| {
        const enc_len = try vli.encode(&vli_buf, val);
        try std.testing.expectEqual(vli.size(val), enc_len);
        var decoded: u64 = 0;
        const dec_len = try vli.decode(vli_buf[0..enc_len], &decoded);
        try std.testing.expectEqual(enc_len, dec_len);
        try std.testing.expectEqual(val, decoded);
    }

    // 2. Non-canonical VLI padding rejection (XZ spec Section 1.2)
    const non_canonical_vli = [_]u8{ 0x80, 0x00 }; // 0 encoded with multi-byte trailing zero
    var dummy_vli: u64 = 0;
    try std.testing.expectError(error.InvalidVli, vli.decode(&non_canonical_vli, &dummy_vli));

    // 3. VLI exceeding VLI_MAX (2^63 - 1) rejection
    const too_large_vli = [_]u8{ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01 };
    try std.testing.expectError(error.InvalidVli, vli.decode(&too_large_vli, &dummy_vli));

    // 4. Backward size overflow check in stream footer
    try std.testing.expectError(error.InvalidIndex, stream_footer.encode(.crc64, 3)); // Not multiple of 4
    if (@sizeOf(usize) == 4) {
        var bad_footer: [12]u8 = undefined;
        std.mem.writeInt(u32, bad_footer[4..8], 0xFFFFFFFF, .little); // backward_size * 4 overflows usize on 32-bit
        bad_footer[8] = 0x00;
        bad_footer[9] = 0x04; // crc64
        bad_footer[10] = 'Y';
        bad_footer[11] = 'Z';
        const crc = crc32(bad_footer[4..10]);
        std.mem.writeInt(u32, bad_footer[0..4], crc, .little);
        try std.testing.expectError(error.InvalidIndex, stream_footer.decode(&bad_footer));
    }

    // 5. Index record count limit rejection
    var bad_index: [16]u8 = @splat(0);
    bad_index[0] = 0x00; // Index Indicator
    _ = try vli.encode(bad_index[1..], 2000000); // Exceeds 1,000,000 records
    const idx_crc = crc32(bad_index[0..12]);
    std.mem.writeInt(u32, bad_index[12..16], idx_crc, .little);
    try std.testing.expectError(error.InvalidRecordCount, index.decode(std.testing.allocator, &bad_index));

    // 6. Safe rejection of truncated XZ stream (< 32 bytes)
    const truncated_stream = [_]u8{ 0xFD, '7', 'z', 'X', 'Z', 0x00 };
    try std.testing.expectError(error.TruncatedInput, decompress(std.testing.allocator, &truncated_stream, .{}));

    // 7. Caller-buffer exhaustion in decompressInto
    const sample = "Arbitrary sample text for caller buffer boundary testing";
    const comp_sample = try compress(std.testing.allocator, sample, .{});
    defer std.testing.allocator.free(comp_sample);
    var tiny_dest: [4]u8 = undefined;
    try std.testing.expectError(error.OutputTooSmall, decompressInto(comp_sample, &tiny_dest, .{}));
}

test "adversarial: fuzzing and malformed stream resilience" {
    const text = "Testing adversarial fuzzing and malformed stream resilience across all components of xz.zig.";
    const comp_xz = try compress(std.testing.allocator, text, .{ .check = .crc64 });
    defer std.testing.allocator.free(comp_xz);

    // 1. Truncated streams: every prefix from 0 to comp_xz.len - 1 must fail safely
    for (0..comp_xz.len - 1) |i| {
        const res = decompress(std.testing.allocator, comp_xz[0..i], .{});
        if (res) |d| {
            std.testing.allocator.free(d);
        } else |_| {}
    }

    // 2. Pseudo-random fuzzing (100 iterations of random garbage inputs)
    var prng = std.Random.DefaultPrng.init(0x87654321);
    const rand = prng.random();
    var random_buf: [256]u8 = undefined;

    for (0..100) |_| {
        const len = rand.uintLessThan(usize, random_buf.len) + 1;
        rand.bytes(random_buf[0..len]);

        const r1 = decompress(std.testing.allocator, random_buf[0..len], .{});
        if (r1) |d| std.testing.allocator.free(d) else |_| {}

        var out_buf: [512]u8 = undefined;
        _ = decompressInto(random_buf[0..len], &out_buf, .{}) catch {};
    }

    // 3. Bit mutation fuzzing on valid XZ container
    var mutated: [512]u8 = undefined;
    if (comp_xz.len <= mutated.len) {
        @memcpy(mutated[0..comp_xz.len], comp_xz);
        for (0..comp_xz.len) |byte_idx| {
            mutated[byte_idx] ^= 0xAA;
            const r = decompress(std.testing.allocator, mutated[0..comp_xz.len], .{});
            if (r) |d| std.testing.allocator.free(d) else |_| {}
            mutated[byte_idx] ^= 0xAA; // restore
        }
    }

    // 4. Inconsistent stream flags: header has CRC32, footer has CRC64
    var flags_mismatch: [256]u8 = undefined;
    const written = try compressInto(text, &flags_mismatch, .{ .check = .crc32 });
    // Corrupt footer check flags (byte written - 3 is flags byte in footer)
    flags_mismatch[written - 3] = 0x04; // CRC64 in footer
    // Recompute footer CRC32
    const footer_crc = crc32(flags_mismatch[written - 8 .. written - 2]);
    std.mem.writeInt(u32, flags_mismatch[written - 12 .. written - 8][0..4], footer_crc, .little);
    try std.testing.expectError(error.StreamFlagsMismatch, decompress(std.testing.allocator, flags_mismatch[0..written], .{}));
}

test "xz: max_output_size limits decompression bomb" {
    const text = "Repetitive data pattern for testing decompression bomb caps in XZ containers. " ++
        "Repetitive data pattern for testing decompression bomb caps in XZ containers. " ++
        "Repetitive data pattern for testing decompression bomb caps in XZ containers.";
    const comp = try compress(std.testing.allocator, text, .{});
    defer std.testing.allocator.free(comp);

    // Limit output to less than actual size
    const limit = text.len / 2;
    try std.testing.expectError(error.ExceededOutputLimit, decompress(std.testing.allocator, comp, .{ .max_output_size = limit }));
}

test "xz: dict_size_limit limits memory allocation" {
    const text = "Testing dictionary size limit constraint on XZ decompression.";
    // Compress with preset 6 (8 MiB dictionary)
    const comp = try compress(std.testing.allocator, text, .{ .level = 6 });
    defer std.testing.allocator.free(comp);

    // Set limit to 64 KiB, which is below the 8 MiB dictionary declared in block header
    try std.testing.expectError(error.ExceededMemoryLimit, decompress(std.testing.allocator, comp, .{ .dict_size_limit = 64 * 1024 }));
}
