//! Configuration options and presets for XZ container streams.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

const std = @import("std");

/// XZ Block Check Type (XZ Specification §2.1.1.2).
///
/// Encoded as a 4-bit identifier in the Stream Flags of every stream header and footer.
/// The selected check algorithm runs over each block's uncompressed output and is stored
/// immediately after the block payload; mismatches return `error.ChecksumMismatch`.
pub const CheckType = enum(u4) {
    /// No integrity check. Fastest; zero byte overhead per block.
    none = 0x00,
    /// IEEE 802.3 CRC32 (polynomial 0xEDB88320). 4 bytes per block.
    crc32 = 0x01,
    /// ECMA-182 CRC64 (polynomial 0xC96C5795D7870F42). 8 bytes per block. Default.
    crc64 = 0x04,
    /// Cryptographic SHA-256 digest. 32 bytes per block.
    sha256 = 0x0A,
    _,

    /// Returns the on-disk size of this check field in bytes.
    pub fn checkSize(self: CheckType) usize {
        return switch (self) {
            .none => 0,
            .crc32 => 4,
            .crc64 => 8,
            .sha256 => 32,
            _ => 0,
        };
    }
};

/// Compression options for XZ container generation.
pub const CompressOptions = struct {
    /// Block integrity check algorithm (default: CRC64 per XZ recommendation).
    check: CheckType = .crc64,

    /// LZMA2 compression preset (0 = fastest / store, 6 = balanced default, 9 = maximum ratio).
    ///
    /// Preset → dictionary size mapping:
    /// | Preset | Dict Size |
    /// |--------|-----------|
    /// | 0      | 4 KiB     |
    /// | 1      | 64 KiB    |
    /// | 2      | 256 KiB   |
    /// | 3      | 1 MiB     |
    /// | 4      | 2 MiB     |
    /// | 5      | 4 MiB     |
    /// | 6      | 8 MiB     |
    /// | 7      | 16 MiB    |
    /// | 8      | 32 MiB    |
    /// | 9      | 64 MiB    |
    level: u4 = 6,

    /// Override the LZMA2 dictionary size in bytes (4 KiB – 1 GiB).
    /// When non-null, takes precedence over the `level`-derived size.
    dict_size: ?u32 = null,

    /// Prepend an x86/x64 BCJ branch-call-jump filter (filter ID 0x04) before LZMA2.
    /// Improves compression ratio for native x86 and x64 executables.
    bcj_x86: bool = false,

    /// Prepend a delta filter (filter ID 0x03) with the specified byte distance (1..256).
    /// Improves compression ratio for PCM audio, pixel data, and similar structured streams.
    delta_distance: ?u8 = null,
};

/// Decompression options for XZ container decoding.
pub const DecompressOptions = struct {
    /// When `true` (default), every block's CRC32/CRC64/SHA-256 and all header CRC32 fields
    /// are verified after decoding. Set to `false` only if checksum-less speed is required.
    verify_checksum: bool = true,

    /// Maximum memory limit in bytes to guard against decompression bombs.
    /// If the decoded block header requests a dictionary larger than this limit,
    /// decoding halts immediately with `error.ExceededMemoryLimit`.
    ///
    /// Default: 256 MiB.
    memlimit: usize = 256 * 1024 * 1024,

    /// Alias for memlimit to align with lzma2.zig naming convention.
    /// Default: 256 MiB.
    dict_size_limit: usize = 256 * 1024 * 1024,

    /// Maximum uncompressed output size in bytes across the entire stream.
    ///
    /// Defense-in-depth against decompression bombs (CWE-409): XZ containers can encode
    /// blocks that expand into gigabytes or petabytes from small compressed payloads.
    /// When a stream's cumulative uncompressed byte count would exceed this limit, decoding
    /// halts immediately with `error.ExceededOutputLimit` before memory is exhausted.
    ///
    /// Default: `null` (no limit). Always set this when processing untrusted input.
    max_output_size: ?usize = null,

    /// Returns the effective memory limit taking the minimum of `memlimit` and `dict_size_limit`.
    pub fn getEffectiveMemlimit(self: DecompressOptions) usize {
        return @min(self.memlimit, self.dict_size_limit);
    }
};
