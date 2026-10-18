# Memory Management & Safety Guide

`xz.zig` is designed for predictable memory usage, robust resource bounds, and safe handling of untrusted input.

---

## 1. Ownership & Allocator Rules

`xz.zig` follows standard Zig ownership conventions:

- Any function accepting `std.mem.Allocator` allocates memory on the caller's behalf.
- The caller owns the returned slice and is responsible for freeing it:
  ```zig
  const comp = try xz.compress(allocator, data, .{});
  defer allocator.free(comp);
  ```
- Functions named `compressInto` and `decompressInto` perform **zero heap allocations**. They write directly into caller-provided slices and return the number of bytes written.

---

## 2. Bounded Streaming Pipelines

In streaming operations (`compressStream` and `decompressStream`), data is processed block by block through chunked buffers. Memory consumption remains bounded regardless of input file size:

```zig
try xz.compressStream(allocator, &file_reader, &network_writer, .{ .check = .crc64 });
```

This prevents arbitrarily large files from triggering out-of-memory errors on memory-constrained systems.

---

## 3. Defense Against Hostile Payloads

When processing untrusted `.xz` archives from external networks:

- **Decompression Bombs**: Use `max_output_size` in `DecompressOptions` to enforce an upper bound on unpacked bytes. If a stream attempts to produce more data than allowed, `error.ExceededSizeLimit` is immediately returned before memory is exhausted.
- **Dictionary Size Constraints**: The `dict_size_limit` option prevents malicious streams from forcing allocations of gigabyte-scale sliding dictionaries.
- **Padding & Checksum Verification**: Corrupted payloads or altered bytes trigger immediate validation failures (`error.ChecksumMismatch`, `error.InvalidPadding`, or `error.CorruptData`).
