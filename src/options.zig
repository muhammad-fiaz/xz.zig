//! Configuration options and presets for XZ streams.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");

/// XZ Block Check Types (specified in Section 2.1.1.2 of XZ specification)
pub const CheckType = enum(u4) {
    none = 0x00,
    crc32 = 0x01,
    crc64 = 0x04,
    sha256 = 0x0A,
    _,

    /// Size of the Check field in bytes.
    pub fn checkSize(self: CheckType) usize {
        return switch (self) {
            .none => 0,
            .crc32 => 4,
            .crc64 => 8,
            .sha256 => 32,
            else => 0,
        };
    }
};

/// Compression options for XZ container generation.
pub const CompressOptions = struct {
    /// Integrity check type to embed in the stream (default: CRC64 as per XZ standard).
    check: CheckType = .crc64,

    /// Compression preset level (0 = fastest/copy, 6 = default, 9 = maximum).
    level: u4 = 6,

    /// Override dictionary size in bytes (e.g. 64 KiB, 1 MiB, 8 MiB).
    dict_size: ?u32 = null,

    /// Enable optional x86 BCJ branch-call-jump filter for x86/x64 executables.
    bcj_x86: bool = false,

    /// Enable optional delta filter with distance (1..256 bytes).
    delta_distance: ?u8 = null,
};

/// Decompression options for XZ container decoding.
pub const DecompressOptions = struct {
    /// Whether to verify block CRC32/CRC64/SHA-256 and header CRCs.
    verify_checksum: bool = true,

    /// Maximum memory allocation limit in bytes to guard against decompression bombs.
    memlimit: usize = 256 * 1024 * 1024, // 256 MiB default

    /// Maximum decoded output size limit in bytes (optional safety bound).
    max_output_size: ?usize = null,
};
