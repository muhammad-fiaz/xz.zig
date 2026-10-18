# XZ API Reference Overview

The `xz` package exports top-level compression and decompression functions, streaming engines, integrity check algorithms, container format components, and error sets.

Import the package:

```zig
const xz = @import("xz");
```

---

## Top-Level Functions

### `xz.compress`
```zig
pub fn compress(allocator: std.mem.Allocator, src: []const u8, options: CompressOptions) ![]u8
```
Compresses `src` into a newly allocated slice containing a complete `.xz` stream.
- **Parameters**:
  - `allocator`: Memory allocator for the output slice.
  - `src`: Uncompressed input bytes.
  - `options`: Compression options (`check`, `enable_bcj_x86`, `delta_distance`, `lzma2_options`).
- **Returns**: Owned slice containing the valid XZ file. Must be freed by caller using `allocator.free()`.
- **Errors**: `OutOfMemory`, `InvalidOptions`, `OutputTooSmall`.

---

### `xz.decompress`
```zig
pub fn decompress(allocator: std.mem.Allocator, src: []const u8, options: DecompressOptions) ![]u8
```
Decompresses an `.xz` container stream `src` into a newly allocated slice.
- **Parameters**:
  - `allocator`: Memory allocator for the output slice.
  - `src`: Complete XZ container bytes.
  - `options`: Decompression parameters (`max_output_size`, `dict_size_limit`).
- **Returns**: Owned slice containing restored bytes. Must be freed by caller using `allocator.free()`.
- **Errors**: `OutOfMemory`, `InvalidMagic`, `ChecksumMismatch`, `CorruptData`, `ExceededSizeLimit`, `UnsupportedFilter`.

---

### `xz.compressInto`
```zig
pub fn compressInto(dst: []u8, src: []const u8, options: CompressOptions) !usize
```
Compresses `src` directly into caller-provided buffer `dst` with **zero heap allocations**.
- **Returns**: The number of bytes written to `dst`.
- **Errors**: `OutputTooSmall`.

---

### `xz.decompressInto`
```zig
pub fn decompressInto(dst: []u8, src: []const u8, options: DecompressOptions) !usize
```
Decompresses `src` directly into caller-provided buffer `dst` with **zero heap allocations**.
- **Returns**: The number of bytes written to `dst`.
- **Errors**: `OutputTooSmall`, `InvalidMagic`, `ChecksumMismatch`, `CorruptData`.

---

### `xz.compressStream`
```zig
pub fn compressStream(reader: anytype, writer: anytype, options: CompressOptions) !void
```
Incrementally reads uncompressed data from `reader` and writes XZ container blocks to `writer`.

---

### `xz.decompressStream`
```zig
pub fn decompressStream(reader: anytype, writer: anytype, options: DecompressOptions) !void
```
Incrementally reads an XZ container stream from `reader` and writes decompressed data to `writer`.

---

### `xz.isXzStream`
```zig
pub fn isXzStream(data: []const u8) bool
```
Returns `true` if `data` begins with the 6-byte XZ header magic `FD 37 7A 58 5A 00`.

---

## Submodule Exports

- **`xz.checksum`**: Checksum routines (`crc32`, `crc64`, `sha256`).
- **`xz.filters`**: Filter IDs (`FILTER_LZMA2`, `FILTER_DELTA`, `FILTER_X86_BCJ`) and state structures.
- **`xz.stream_header`**: Stream header parsing and serialization.
- **`xz.stream_footer`**: Stream footer validation and backward size calculations.
- **`xz.block_header`**: Block header flags, sizes, filter chains, and CRC32.
- **`xz.index`**: Index records, VLI serialization, padding, and CRC32.
- **`xz.vli`**: Variable-Length Integer encoders and decoders.
- **`xz.errors`**: Comprehensive error definitions.
