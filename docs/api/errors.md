# Error Sets

`xz.zig` defines structured error sets covering container formatting, block verification, filter validation, and memory capacity limits.

---

## 1. `FormatError`

Errors related to XZ stream headers, block headers, indexes, and framing:

```zig
pub const FormatError = error{
    InvalidMagic,           // Magic bytes did not match header (FD 37 7A 58 5A 00) or footer (59 5A)
    InvalidHeaderSize,      // Header size field was malformed or less than 8 bytes
    InvalidFlags,           // Reserved flag bits were non-zero or unsupported check type
    InvalidVli,             // Variable-length integer exceeded 9 bytes or was malformed
    InvalidPadding,         // Header, block, or index padding contained non-null bytes
    InvalidIndex,           // Index records were inconsistent with actual stream blocks
    BackwardSizeMismatch,   // Footer backward size did not match real index size
    StreamFlagsMismatch,    // Footer stream flags did not match header stream flags
    TruncatedInput,         // Input ended prematurely before end of stream or field
    UnexpectedEof,          // End-of-file reached inside a payload block
    InvalidControlByte,     // Invalid chunk control byte inside an LZMA2 payload
    InvalidRecordCount,     // Number of index records exceeded permitted limits
    SizeMismatch,           // Decoded byte count did not match declared uncompressed size
    OutputTooSmall,         // Destination buffer provided by caller was too small
};
```

---

## 2. `ChecksumError`

Errors related to block check calculation and verification:

```zig
pub const ChecksumError = error{
    UnsupportedCheck,       // Requested or encountered check ID is not supported
    ChecksumMismatch,       // Calculated block check does not match stored check bytes
};
```

---

## 3. `FilterError`

Errors related to filter chain initialization, property parsing, and order:

```zig
pub const FilterError = error{
    UnsupportedFilter,          // Filter ID is not supported (e.g. unknown architecture BCJ filter)
    TooManyFilters,             // Filter chain declared more than 4 filters
    InvalidFilterProperties,    // Filter property byte length or format was invalid
    InvalidFilterOrder,         // Non-last filter was placed in last position or vice-versa
    DictionaryTooLarge,         // LZMA2 dictionary size exceeded configured decoder limit
};
```

---

## 4. `CompressError` & `DecompressError`

Combined error unions returned by top-level operations:

```zig
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
```
