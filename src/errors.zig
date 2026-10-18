//! Error sets for XZ container compression and decompression.
//!
//! Author: muhammad-fiaz
//! License: MIT
//! Repository: https://github.com/muhammad-fiaz/xz.zig

pub const Error = FormatError || ChecksumError || FilterError || CompressError || DecompressError;

pub const FormatError = error{
    InvalidMagic,
    InvalidHeaderSize,
    InvalidFlags,
    InvalidVli,
    InvalidPadding,
    InvalidIndex,
    BackwardSizeMismatch,
    StreamFlagsMismatch,
    TruncatedInput,
    UnexpectedEof,
    InvalidControlByte,
    InvalidRecordCount,
    SizeMismatch,
    OutputTooSmall,
};

pub const ChecksumError = error{
    UnsupportedCheck,
    ChecksumMismatch,
};

pub const FilterError = error{
    UnsupportedFilter,
    TooManyFilters,
    InvalidFilterProperties,
    InvalidFilterOrder,
    DictionaryTooLarge,
};

pub const CompressError = error{
    OutputTooSmall,
    OutOfMemory,
    InputTooLarge,
} || FormatError || ChecksumError || FilterError;

pub const DecompressError = error{
    OutputTooSmall,
    OutOfMemory,
    CorruptData,
    ExceededMemoryLimit,
    ExceededOutputLimit,
} || FormatError || ChecksumError || FilterError;
