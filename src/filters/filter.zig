//! Filter identifiers and constants (Section 5.3).
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

pub const FILTER_DELTA: u64 = 0x03;
pub const FILTER_X86_BCJ: u64 = 0x04;
pub const FILTER_POWERPC: u64 = 0x05;
pub const FILTER_IA64: u64 = 0x06;
pub const FILTER_ARM: u64 = 0x07;
pub const FILTER_ARMTHUMB: u64 = 0x08;
pub const FILTER_SPARC: u64 = 0x09;
pub const FILTER_ARM64: u64 = 0x0A;
pub const FILTER_RISCV: u64 = 0x0B;
pub const FILTER_LZMA2: u64 = 0x21;

/// Returns true if the filter is allowed as the last filter in an XZ filter chain.
pub fn isLastFilter(filter_id: u64) bool {
    return filter_id == FILTER_LZMA2;
}

/// Returns true if the filter is a supported non-last filter.
pub fn isSupportedFilter(filter_id: u64) bool {
    return filter_id == FILTER_LZMA2 or filter_id == FILTER_X86_BCJ or filter_id == FILTER_DELTA;
}
