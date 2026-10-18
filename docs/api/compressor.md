# XZ Compression API

`xz.zig` provides single-call heap allocating compression, zero-allocation caller-buffer operations, and incremental streaming compressors.

---

## 1. `xz.compress`

```zig
pub fn compress(allocator: std.mem.Allocator, src: []const u8, options: CompressOptions) ![]u8
```

Compresses the input byte slice `src` into a complete XZ container file.

- **Parameters**:
  - `allocator`: Memory allocator used to allocate the output buffer.
  - `src`: Input slice to compress.
  - `options`: Compression options (`check`, `enable_bcj_x86`, `delta_distance`, `lzma2_options`).
- **Returns**: An allocated slice containing the valid XZ stream. The caller owns this memory and must free it with `allocator.free()`.
- **Errors**: `OutOfMemory`, `InvalidOptions`.

---

## 2. `xz.compressInto`

```zig
pub fn compressInto(dst: []u8, src: []const u8, options: CompressOptions) !usize
```

Compresses `src` into caller-provided buffer `dst` with **zero dynamic heap allocations**.

- **Parameters**:
  - `dst`: Pre-allocated buffer provided by the caller.
  - `src`: Input data to compress.
  - `options`: Compression options.
- **Returns**: Number of bytes written to `dst`.
- **Errors**: `OutputTooSmall`.

---

## 3. `xz.compressStream`

```zig
pub fn compressStream(reader: anytype, writer: anytype, options: CompressOptions) !void
```

Streams uncompressed data from any reader supporting `.read(buf)` and writes XZ container blocks to any writer supporting `.writeAll(bytes)`.

---

## 4. `xz.StreamingCompressor`

Stateful incremental block compressor for feeding blocks sequentially:

```zig
pub const StreamingCompressor = struct {
    allocator: std.mem.Allocator,
    options: CompressOptions,

    pub fn init(allocator: std.mem.Allocator, options: CompressOptions) StreamingCompressor;
    pub fn startStream(self: *StreamingCompressor, writer: anytype) !void;
    pub fn writeBlock(self: *StreamingCompressor, writer: anytype, data: []const u8) !void;
    pub fn finishStream(self: *StreamingCompressor, writer: anytype) !void;
    pub fn deinit(self: *StreamingCompressor) void;
};
```
