//! Delta filter implementation (Section 5.3.3).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");
const errors = @import("../errors.zig");

pub const State = struct {
    distance: usize,
    pos: u8 = 0,
    history: [256]u8 = @splat(0),

    pub fn init(distance: u8) State {
        return State{
            .distance = @as(usize, distance) + 1,
        };
    }

    pub fn encode(self: *State, buffer: []u8) void {
        for (buffer) |*b| {
            const hist_idx = @as(u8, @truncate(self.pos +% @as(u8, @truncate(self.distance))));
            const tmp = b.* -% self.history[hist_idx];
            self.history[self.pos] = b.*;
            self.pos -%= 1;
            b.* = tmp;
        }
    }

    pub fn decode(self: *State, buffer: []u8) void {
        for (buffer) |*b| {
            const hist_idx = @as(u8, @truncate(self.pos +% @as(u8, @truncate(self.distance))));
            const tmp = b.* +% self.history[hist_idx];
            self.history[self.pos] = tmp;
            self.pos -%= 1;
            b.* = tmp;
        }
    }
};

test "delta: encode and decode roundtrip" {
    var state_enc = State.init(3); // distance 4
    var state_dec = State.init(3);

    const original = "Hello World! Test Delta Filter 1234567890";
    var buffer: [64]u8 = undefined;
    @memcpy(buffer[0..original.len], original);

    state_enc.encode(buffer[0..original.len]);
    try std.testing.expect(!std.mem.eql(u8, original, buffer[0..original.len]));

    state_dec.decode(buffer[0..original.len]);
    try std.testing.expectEqualStrings(original, buffer[0..original.len]);
}
