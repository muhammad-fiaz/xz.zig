# XZ Decompression API

`xz.zig` provides single-call heap allocating decompression, zero-allocation caller-buffer operations, and incremental streaming decoders.

---

## 1. `xz.decompress`

```zig
pub fn decompress(allocator: std.mem.Allocator, src: []const u8, options: DecompressOptions) ![]u8
```

Decompresses a complete XZ container byte stream into a newly allocated buffer.

- **Parameters**:
  - `allocator`: Memory allocator used to allocate the output buffer.
  - `src`: Input slice containing the `.xz` file.
  - `options`: Decompression parameters (`max_output_size`, `dict_size_limit`).
- **Returns**: An allocated slice containing the restored original data. The caller owns this memory and must free it with `allocator.free()`.
- **Errors**: `OutOfMemory`, `InvalidMagic`, `ChecksumMismatch`, `CorruptData`, `ExceededSizeLimit`, `UnsupportedFilter`.

---

## 2. `xz.decompressInto`

```zig
pub fn decompressInto(dst: []u8, src: []const u8, options: DecompressOptions) !usize
```

Decompresses an `.xz` container stream directly into caller-provided buffer `dst` with **zero dynamic heap allocations**.

- **Parameters**:
  - `dst`: Pre-allocated buffer provided by the caller.
  - `src`: Input XZ stream to decompress.
  - `options`: Decompression options.
- **Returns**: Number of bytes written to `dst`.
- **Errors**: `OutputTooSmall`, `InvalidMagic`, `ChecksumMismatch`, `CorruptData`.

---

## 3. `xz.decompressStream`

```zig
pub fn decompressStream(reader: anytype, writer: anytype, options: DecompressOptions) !void
```

Streams an XZ container from `reader` and writes restored uncompressed data to `writer`.

---

## 4. `xz.isXzStream`

```zig
pub fn isXzStream(data: []const u8) bool
```

Inspects the first 6 bytes of `data` to verify if they match the official XZ stream header magic (`FD 37 7A 58 5A 00`).
