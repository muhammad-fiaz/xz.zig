//! Streaming decompression for XZ streams (Section 2 & 3).
//!
//! Provides genuine bounded-memory block-by-block streaming decompression
//! with integrity verification, filter pipeline reversal, and footer validation.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");
const options_mod = @import("../options.zig");
const DecompressOptions = options_mod.DecompressOptions;
const CheckType = options_mod.CheckType;

const stream_header = @import("../format/stream_header.zig");
const stream_footer = @import("../format/stream_footer.zig");
const block_header = @import("../format/block_header.zig");
const index_mod = @import("../format/index.zig");
const padding = @import("../format/padding.zig");
const vli_mod = @import("../format/vli.zig");
const filter_mod = @import("../filters/filter.zig");
const lzma2_filter = @import("../filters/lzma2.zig");
const delta = @import("../filters/delta.zig");
const bcj = @import("../filters/bcj.zig");

const crc32_mod = @import("../checksum/crc32.zig");
const crc64_mod = @import("../checksum/crc64.zig");
const sha256_mod = @import("../checksum/sha256.zig");

fn readExact(reader: anytype, buffer: []u8) !void {
    var total: usize = 0;
    while (total < buffer.len) {
        const n = try reader.read(buffer[total..]);
        if (n == 0) return error.TruncatedInput;
        total += n;
    }
}

fn readVli(reader: anytype) !u64 {
    var v: u64 = 0;
    var shift: u6 = 0;
    var i: usize = 0;
    while (i < 9) : (i += 1) {
        var b: [1]u8 = undefined;
        try readExact(reader, &b);
        const byte = b[0];
        v |= @as(u64, byte & 0x7F) << shift;
        if ((byte & 0x80) == 0) {
            if (byte == 0 and i > 0) return error.InvalidVli;
            return v;
        }
        shift += 7;
    }
    return error.InvalidVli;
}

/// Streaming reader/writer pipeline for continuous XZ decompression (including concatenated streams and stream padding).
pub fn decompressStream(reader: anytype, writer: anytype, options: DecompressOptions) !void {
    const allocator = std.heap.smp_allocator;
    var total_decompressed: usize = 0;
    const max_output = options.max_output_size orelse std.math.maxInt(usize);
    var stream_count: usize = 0;

    var first_byte_buf: [1]u8 = undefined;

    while (true) {
        const n = reader.read(&first_byte_buf) catch return error.CorruptData;
        if (n == 0) {
            if (stream_count == 0) return error.TruncatedInput;
            break;
        }

        if (first_byte_buf[0] == 0x00) {
            // Stream Padding: must be 4-byte aligned blocks of 0x00
            var rem_pad: [3]u8 = undefined;
            try readExact(reader, &rem_pad);
            for (rem_pad) |b| {
                if (b != 0x00) return error.InvalidPadding;
            }
            continue;
        }

        if (first_byte_buf[0] != stream_header.HEADER_MAGIC[0]) {
            return error.InvalidMagic;
        }

        // 1. Decode and validate Stream Header (12 bytes)
        var header_buf: [12]u8 = undefined;
        header_buf[0] = first_byte_buf[0];
        try readExact(reader, header_buf[1..12]);
        const check = try stream_header.decode(&header_buf);
        stream_count += 1;

        // Track block records to verify Index
        const Record = index_mod.Record;
        var records: std.ArrayList(Record) = .empty;
        defer records.deinit(allocator);

        // 2. Decode Blocks sequentially
        while (true) {
            var first_b: [1]u8 = undefined;
            try readExact(reader, &first_b);
            if (first_b[0] == 0x00) {
                // 0x00 is Index Indicator: blocks ended, Index begins
                break;
            }

            const encoded_hdr_size = first_b[0];
            const header_size = (@as(usize, encoded_hdr_size) + 1) * 4;
            if (header_size > 1024) return error.InvalidHeaderSize;

            var hdr_buf: [1024]u8 = undefined;
            hdr_buf[0] = first_b[0];
            try readExact(reader, hdr_buf[1..header_size]);

            var filter_buf: [4]block_header.FilterDesc = undefined;
            var prop_buf: [4][32]u8 = undefined;
            const hdr_res = try block_header.BlockHeader.decode(hdr_buf[0..header_size], &filter_buf, &prop_buf);
            const header = hdr_res.header;

            // Validate filters
            if (header.filters.len == 0 or header.filters.len > 4) return error.TooManyFilters;
            const last_filter = header.filters[header.filters.len - 1];
            if (last_filter.id != filter_mod.FILTER_LZMA2) return error.InvalidFilterOrder;
            if (last_filter.properties.len < 1) return error.InvalidFilterProperties;
            // Check LZMA2 dictionary size
            const dict_size = try lzma2_filter.propToDictSize(last_filter.properties[0]);
            if (dict_size > options.getEffectiveMemlimit()) return error.ExceededMemoryLimit;
            for (header.filters[0 .. header.filters.len - 1]) |f| {
                if (!filter_mod.isSupportedFilter(f.id)) return error.UnsupportedFilter;
            }

            // Read Compressed Data for this block
            var comp_buf: std.ArrayList(u8) = .empty;
            defer comp_buf.deinit(allocator);

            if (header.compressed_size) |cs| {
                const cs_usize = @as(usize, @intCast(cs));
                try comp_buf.resize(allocator, cs_usize);
                try readExact(reader, comp_buf.items);
            } else {
                // Read LZMA2 chunks until 0x00 control byte
                while (true) {
                    var ctrl: [1]u8 = undefined;
                    try readExact(reader, &ctrl);
                    try comp_buf.append(allocator, ctrl[0]);
                    const control = ctrl[0];

                    if (control == 0x00) {
                        break;
                    } else if ((control & 0x80) == 0) {
                        if (control > 2) return error.CorruptData;
                        var sz_b: [2]u8 = undefined;
                        try readExact(reader, &sz_b);
                        try comp_buf.appendSlice(allocator, &sz_b);
                        const chunk_size = (@as(usize, sz_b[0]) << 8 | @as(usize, sz_b[1])) + 1;
                        const cur_len = comp_buf.items.len;
                        try comp_buf.resize(allocator, cur_len + chunk_size);
                        try readExact(reader, comp_buf.items[cur_len .. cur_len + chunk_size]);
                    } else {
                        var chunk_hdr: [4]u8 = undefined;
                        try readExact(reader, &chunk_hdr);
                        try comp_buf.appendSlice(allocator, &chunk_hdr);
                        const mode: u2 = @truncate((control >> 5) & 3);
                        const prop_len: usize = if (mode >= 2) 1 else 0;
                        if (prop_len == 1) {
                            var p_byte: [1]u8 = undefined;
                            try readExact(reader, &p_byte);
                            try comp_buf.append(allocator, p_byte[0]);
                        }
                        const pack_size = (@as(usize, chunk_hdr[2]) << 8 | @as(usize, chunk_hdr[3])) + 1;
                        const cur_len = comp_buf.items.len;
                        try comp_buf.resize(allocator, cur_len + pack_size);
                        try readExact(reader, comp_buf.items[cur_len .. cur_len + pack_size]);
                    }
                }
            }

            const compressed_len = comp_buf.items.len;

            // Block Padding
            const block_pad_len = padding.pad4(compressed_len);
            if (block_pad_len > 0) {
                var pad_buf: [4]u8 = undefined;
                try readExact(reader, pad_buf[0..block_pad_len]);
                try padding.validatePadding(pad_buf[0..block_pad_len]);
            }

            // Check field
            const check_size = check.checkSize();
            var check_buf: [32]u8 = undefined;
            if (check_size > 0) {
                try readExact(reader, check_buf[0..check_size]);
            }

            // Decompress LZMA2 payload
            const remaining_allowed = if (max_output > total_decompressed) max_output - total_decompressed else 0;
            const lzma2_decomp_opts = lzma2_filter.lzma2.DecompressOptions{
                .dict_size_limit = dict_size,
                .max_output_size = remaining_allowed,
            };
            const decompressed = try lzma2_filter.decompress(allocator, comp_buf.items, lzma2_decomp_opts);
            defer allocator.free(decompressed);

            if (header.uncompressed_size) |us| {
                if (decompressed.len != us) return error.SizeMismatch;
            }

            // Reverse non-last filters (BCJ / Delta)
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

            // Validate Check
            if (options.verify_checksum and check_size > 0) {
                switch (check) {
                    .none => {},
                    .crc32 => {
                        const actual_crc = crc32_mod.hash(decompressed);
                        const expected_crc = std.mem.readInt(u32, check_buf[0..4], .little);
                        if (actual_crc != expected_crc) return error.ChecksumMismatch;
                    },
                    .crc64 => {
                        const actual_crc = crc64_mod.hash(decompressed);
                        const expected_crc = std.mem.readInt(u64, check_buf[0..8], .little);
                        if (actual_crc != expected_crc) return error.ChecksumMismatch;
                    },
                    .sha256 => {
                        const actual_sha = sha256_mod.hash(decompressed);
                        if (!std.mem.eql(u8, &actual_sha, check_buf[0..32])) return error.ChecksumMismatch;
                    },
                    else => return error.UnsupportedCheck,
                }
            }

            total_decompressed += decompressed.len;
            if (total_decompressed > max_output) return error.ExceededOutputLimit;

            // Write decompressed block directly to output writer
            try writer.writeAll(decompressed);

            const unpadded_size = header_size + compressed_len + check_size;
            try records.append(allocator, .{
                .unpadded_size = unpadded_size,
                .uncompressed_size = decompressed.len,
            });
        }

        // 3. Read and validate Index
        const num_records_vli = try readVli(reader);
        if (num_records_vli != records.items.len) return error.InvalidIndex;

        var index_bytes: std.ArrayList(u8) = .empty;
        defer index_bytes.deinit(allocator);
        try index_bytes.append(allocator, 0x00); // Index Indicator

        var num_rec_buf: [9]u8 = undefined;
        const num_rec_len = try vli_mod.encode(&num_rec_buf, num_records_vli);
        try index_bytes.appendSlice(allocator, num_rec_buf[0..num_rec_len]);

        for (records.items) |rec| {
            const expected_unpadded = try readVli(reader);
            const expected_uncompressed = try readVli(reader);
            if (rec.unpadded_size != expected_unpadded or rec.uncompressed_size != expected_uncompressed) {
                return error.InvalidIndex;
            }

            var r_buf: [18]u8 = undefined;
            const unp_len = try vli_mod.encode(r_buf[0..9], expected_unpadded);
            const unc_len = try vli_mod.encode(r_buf[9..18], expected_uncompressed);
            try index_bytes.appendSlice(allocator, r_buf[0..unp_len]);
            try index_bytes.appendSlice(allocator, r_buf[9 .. 9 + unc_len]);
        }

        const index_pad_len = padding.pad4(index_bytes.items.len);
        if (index_pad_len > 0) {
            var pad_buf: [4]u8 = undefined;
            try readExact(reader, pad_buf[0..index_pad_len]);
            try padding.validatePadding(pad_buf[0..index_pad_len]);
            try index_bytes.appendSlice(allocator, pad_buf[0..index_pad_len]);
        }

        var index_crc_buf: [4]u8 = undefined;
        try readExact(reader, &index_crc_buf);
        const expected_index_crc = std.mem.readInt(u32, &index_crc_buf, .little);
        const actual_index_crc = crc32_mod.hash(index_bytes.items);
        if (actual_index_crc != expected_index_crc) return error.InvalidIndex;

        const total_index_size = index_bytes.items.len + 4;

        // 4. Read and validate Stream Footer (12 bytes)
        var footer_buf: [12]u8 = undefined;
        try readExact(reader, &footer_buf);
        const footer = try stream_footer.decode(&footer_buf);
        if (footer.check != check) return error.StreamFlagsMismatch;
        if (footer.index_size != total_index_size) return error.BackwardSizeMismatch;
    }
}
