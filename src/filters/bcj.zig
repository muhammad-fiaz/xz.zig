//! x86 BCJ (Branch/Call/Jump) filter implementation (Section 5.3.2).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");

fn test86MSByte(b: u8) bool {
    return b == 0x00 or b == 0xFF;
}

const MASK_TO_BIT_NUMBER = [5]u32{ 0, 1, 2, 2, 3 };

pub const X86State = struct {
    prev_mask: u32 = 0,
    prev_pos: u32 = 0,

    pub fn code(self: *X86State, now_pos: u32, is_encoder: bool, buffer: []u8) usize {
        if (buffer.len < 5) return 0;

        var prev_mask = self.prev_mask;
        var prev_pos = self.prev_pos;

        if (now_pos -% prev_pos > 5) {
            prev_pos = now_pos -% 5;
        }

        const limit = buffer.len - 5;
        var buffer_pos: usize = 0;

        while (buffer_pos <= limit) {
            const b0 = buffer[buffer_pos];
            if (b0 != 0xE8 and b0 != 0xE9) {
                buffer_pos += 1;
                continue;
            }

            const offset = now_pos + @as(u32, @intCast(buffer_pos)) -% prev_pos;
            prev_pos = now_pos + @as(u32, @intCast(buffer_pos));

            if (offset > 5) {
                prev_mask = 0;
            } else {
                var i: u32 = 0;
                while (i < offset) : (i += 1) {
                    prev_mask &= 0x77;
                    prev_mask <<= 1;
                }
            }

            var b = buffer[buffer_pos + 4];
            if (test86MSByte(b) and (prev_mask >> 1) <= 4 and (prev_mask >> 1) != 3) {
                var src: u32 = (@as(u32, b) << 24) |
                    (@as(u32, buffer[buffer_pos + 3]) << 16) |
                    (@as(u32, buffer[buffer_pos + 2]) << 8) |
                    @as(u32, buffer[buffer_pos + 1]);

                var dest: u32 = undefined;
                while (true) {
                    if (is_encoder) {
                        dest = src +% (now_pos + @as(u32, @intCast(buffer_pos)) + 5);
                    } else {
                        dest = src -% (now_pos + @as(u32, @intCast(buffer_pos)) + 5);
                    }

                    if (prev_mask == 0) break;

                    const bit_idx = MASK_TO_BIT_NUMBER[prev_mask >> 1];
                    b = @as(u8, @truncate(dest >> @as(u5, @intCast(24 - bit_idx * 8))));
                    if (!test86MSByte(b)) break;

                    src = dest ^ ((@as(u32, 1) << @as(u5, @intCast(32 - bit_idx * 8))) - 1);
                }

                buffer[buffer_pos + 4] = @as(u8, @truncate(~(((dest >> 24) & 1) -% 1)));
                buffer[buffer_pos + 3] = @as(u8, @truncate(dest >> 16));
                buffer[buffer_pos + 2] = @as(u8, @truncate(dest >> 8));
                buffer[buffer_pos + 1] = @as(u8, @truncate(dest));
                buffer_pos += 5;
                prev_mask = 0;
            } else {
                buffer_pos += 1;
                prev_mask |= 1;
                if (test86MSByte(b)) prev_mask |= 0x10;
            }
        }

        self.prev_mask = prev_mask;
        self.prev_pos = prev_pos;
        return buffer_pos;
    }
};

test "bcj: x86 filter roundtrip" {
    var enc_state = X86State{};
    var dec_state = X86State{};

    // Dummy x86 code with E8 and E9 call/jump instructions
    var data = [_]u8{ 0x90, 0xE8, 0x10, 0x00, 0x00, 0x00, 0x90, 0xE9, 0x20, 0x00, 0x00, 0x00, 0x90, 0x90 };
    var copy: [14]u8 = undefined;
    @memcpy(&copy, &data);

    _ = enc_state.code(0, true, &data);
    _ = dec_state.code(0, false, &data);

    try std.testing.expectEqualSlices(u8, &copy, &data);
}
