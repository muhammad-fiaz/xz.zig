# Options & Integrity Checks

`xz.zig` provides structured configuration types for controlling block integrity checks, pre-filters, and safety bounds.

---

## `xz.CheckType`

Enumeration of supported XZ integrity check algorithms:

```zig
pub const CheckType = enum(u4) {
    none = 0x00,
    crc32 = 0x01,
    crc64 = 0x04,
    sha256 = 0x0A,

    pub fn checkSize(self: CheckType) usize;
    pub fn isValid(id: u4) bool;
};
```

### Methods:
- **`checkSize()`**: Returns the byte size of the check field (`0` for `.none`, `4` for `.crc32`, `8` for `.crc64`, `32` for `.sha256`).
- **`isValid(id)`**: Validates whether a numeric 4-bit check ID corresponds to a recognized check type.

---

## `xz.CompressOptions`

Configuration struct passed to `xz.compress()`, `xz.compressInto()`, and `xz.compressStream()`:

```zig
pub const CompressOptions = struct {
    check: CheckType = .crc64,
    enable_bcj_x86: bool = false,
    delta_distance: ?u8 = null,
    lzma2_options: lzma2.Options = .{},
};
```

### Field Descriptions:
- **`check`**: Integrity check algorithm applied to each block. Default is `.crc64` (standard XZ specification default).
- **`enable_bcj_x86`**: When `true`, prepends the x86 BCJ branch filter (`0x04`) to the filter chain to optimize executable machine code.
- **`delta_distance`**: When set to a value between `1` and `256`, prepends the Delta filter (`0x03`) to the filter chain.
- **`lzma2_options`**: Options passed to the underlying `lzma2.zig` codec (compression level 0..9, dictionary size, etc.).

---

## `xz.DecompressOptions`

Configuration struct passed to `xz.decompress()`, `xz.decompressInto()`, and `xz.decompressStream()`:

```zig
pub const DecompressOptions = struct {
    max_output_size: ?usize = null,
    dict_size_limit: ?u32 = null,
};
```

### Field Descriptions:
- **`max_output_size`**: Maximum number of uncompressed bytes allowed before returning `error.ExceededSizeLimit` (defense against decompression bombs). Default is unlimited (`std.math.maxInt(usize)`).
- **`dict_size_limit`**: Maximum sliding dictionary memory window permitted. Default is 1 GiB.
