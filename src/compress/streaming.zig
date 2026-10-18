//! Streaming compression for XZ streams (Section 2 & 3).
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

pub const StreamingCompressor = struct {
    allocator: std.mem.Allocator,
    options: CompressOptions,
    records: std.ArrayList(Record) = .empty,
    buffer: std.ArrayList(u8) = .empty,
    header_written: bool = false,
    block_size: usize = 1024 * 1024, // 1 MiB default block chunking

    pub fn init(allocator: std.mem.Allocator, options: CompressOptions) StreamingCompressor {
        return StreamingCompressor{
            .allocator = allocator,
            .options = options,
        };
    }

    pub fn deinit(self: *StreamingCompressor) void {
        self.records.deinit(self.allocator);
        self.buffer.deinit(self.allocator);
    }

    /// Writes raw uncompressed bytes, buffering and flushing complete blocks.
    pub fn write(self: *StreamingCompressor, writer: anytype, bytes: []const u8) !void {
        if (!self.header_written) {
            const hdr = stream_header.encode(self.options.check);
            try writer.writeAll(&hdr);
            self.header_written = true;
        }

        try self.buffer.appendSlice(self.allocator, bytes);

        while (self.buffer.items.len >= self.block_size) {
            const block_slice = self.buffer.items[0..self.block_size];
            const block_res = try block_compress.encodeBlock(self.allocator, block_slice, self.options);
            defer self.allocator.free(block_res.data);

            try writer.writeAll(block_res.data);
            try self.records.append(self.allocator, block_res.record);

            // Shift remaining bytes
            const remaining = self.buffer.items.len - self.block_size;
            std.mem.copyForwards(u8, self.buffer.items[0..remaining], self.buffer.items[self.block_size..]);
            self.buffer.shrinkRetainingCapacity(remaining);
        }
    }

    /// Flushes any remaining bytes as the final block, emits Index, and emits Stream Footer.
    pub fn finish(self: *StreamingCompressor, writer: anytype) !void {
        if (!self.header_written) {
            const hdr = stream_header.encode(self.options.check);
            try writer.writeAll(&hdr);
            self.header_written = true;
        }

        // Flush remaining buffer
        if (self.buffer.items.len > 0) {
            const block_res = try block_compress.encodeBlock(self.allocator, self.buffer.items, self.options);
            defer self.allocator.free(block_res.data);

            try writer.writeAll(block_res.data);
            try self.records.append(self.allocator, block_res.record);
            self.buffer.clearRetainingCapacity();
        }

        // Emit Index
        const index_size = try index_mod.totalSize(self.records.items);
        const index_buf = try self.allocator.alloc(u8, index_size);
        defer self.allocator.free(index_buf);
        _ = try index_mod.encode(self.records.items, index_buf);
        try writer.writeAll(index_buf);

        // Emit Stream Footer
        const footer_bytes = try stream_footer.encode(self.options.check, index_size);
        try writer.writeAll(&footer_bytes);
    }
};

/// High-level streaming pipeline to compress from any reader to any writer.
pub fn compressStream(reader: anytype, writer: anytype, options: CompressOptions) !void {
    const allocator = std.heap.smp_allocator;
    var comp = StreamingCompressor.init(allocator, options);
    defer comp.deinit();

    var buf: [16384]u8 = undefined;
    while (true) {
        const n = try reader.read(&buf);
        if (n == 0) break;
        try comp.write(writer, buf[0..n]);
    }

    try comp.finish(writer);
}
