const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const message = "Zero-allocation embedded XZ container compression using pre-allocated caller buffers.";

    var comp_buffer: [1024]u8 = undefined;
    var decomp_buffer: [1024]u8 = undefined;

    const comp_size = try xz.compressInto(message, &comp_buffer, .{});
    std.debug.print("Compressed into caller buffer: {d} bytes\n", .{comp_size});

    const decomp_size = try xz.decompressInto(comp_buffer[0..comp_size], &decomp_buffer, .{});
    std.debug.print("Decompressed into caller buffer: {d} bytes\n", .{decomp_size});

    const matches = std.mem.eql(u8, message, decomp_buffer[0..decomp_size]);
    std.debug.print("Verification: {}\n", .{matches});

    std.debug.print("Caller-buffer operations completed successfully!\n", .{});
}
