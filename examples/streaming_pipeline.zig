const std = @import("std");
const xz = @import("xz");

const MemoryReader = struct {
    slice: []const u8,
    pos: usize = 0,

    pub fn read(self: *MemoryReader, buffer: []u8) !usize {
        if (self.pos >= self.slice.len) return 0;
        const available = self.slice.len - self.pos;
        const n = @min(available, buffer.len);
        @memcpy(buffer[0..n], self.slice[self.pos .. self.pos + n]);
        self.pos += n;
        return n;
    }
};

const MemoryWriter = struct {
    list: *std.ArrayList(u8),
    allocator: std.mem.Allocator,

    pub fn writeAll(self: *MemoryWriter, bytes: []const u8) !void {
        self.list.appendSlice(self.allocator, bytes) catch return error.OutOfMemory;
    }
};

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const stream_input = "Streaming XZ pipeline test. Incrementally reading and writing compressed XZ blocks!";

    var input_reader = MemoryReader{ .slice = stream_input };
    var compressed_storage: std.ArrayList(u8) = .empty;
    defer compressed_storage.deinit(allocator);
    var compressed_writer = MemoryWriter{ .list = &compressed_storage, .allocator = allocator };

    // Stream compression
    try xz.compressStream(&input_reader, &compressed_writer, .{});
    std.debug.print("Stream compressed size: {d} bytes\n", .{compressed_storage.items.len});

    // Stream decompression
    var comp_reader = MemoryReader{ .slice = compressed_storage.items };
    var restored_storage: std.ArrayList(u8) = .empty;
    defer restored_storage.deinit(allocator);
    var restored_writer = MemoryWriter{ .list = &restored_storage, .allocator = allocator };

    try xz.decompressStream(&comp_reader, &restored_writer, .{});
    std.debug.print("Stream restored text: \"{s}\"\n", .{restored_storage.items});

    const matches = std.mem.eql(u8, stream_input, restored_storage.items);
    std.debug.print("Stream roundtrip match: {}\n", .{matches});
}
