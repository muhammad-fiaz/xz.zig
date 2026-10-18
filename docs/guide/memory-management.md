# Memory Management & Resource Bounds Guide

`xz.zig` is engineered from the ground up for predictable memory consumption, zero-allocation caller buffers, and robust defense-in-depth against decompression bombs and malformed streams.

---

## 1. Ownership & Allocation Contracts

`xz.zig` strictly follows standard Zig memory ownership conventions:

- **Heap Allocations**: Any function accepting a `std.mem.Allocator` allocates memory on behalf of the caller. The caller owns the returned buffer and is responsible for freeing it:
  ```zig
  const comp = try xz.compress(allocator, data, .{});
  defer allocator.free(comp);

  const orig = try xz.decompress(allocator, comp, .{});
  defer allocator.free(orig);
  ```

- **Zero-Allocation Caller Buffers**: Functions named `compressInto` and `decompressInto` perform **zero heap allocations**. They operate directly on caller-provided memory buffers and return the number of bytes written:
  ```zig
  var out_buf: [4096]u8 = undefined;
  const written = try xz.compressInto(data, &out_buf, .{});
  const comp_slice = out_buf[0..written];
  ```
  If the destination slice is too small to contain the output, the function returns `error.OutputTooSmall` immediately without leaking or allocating memory.

---

## 2. Decompression Bomb Protection (CWE-409)

XZ containers encapsulate LZMA2 compressed blocks and optional filter stages. Highly repetitive or hostile payloads can achieve compression ratios exceeding 1,000:1 (and even millions-to-one on synthetic streams). An attacker could send a 10 KiB payload that attempts to decompress into hundreds of gigabytes, causing denial-of-service through memory exhaustion.

`xz.zig` defends against this with three layered safeguards:

### Uncompressed Output Caps (`max_output_size`)

Set `DecompressOptions.max_output_size` to enforce an absolute uncompressed byte ceiling across multi-block streams:

```zig
const decomp = try xz.decompress(allocator, untrusted_payload, .{
    .max_output_size = 32 * 1024 * 1024, // 32 MiB ceiling
}) catch |err| switch (err) {
    error.ExceededOutputLimit => {
        std.debug.print("Aborted: uncompressed output exceeds 32 MiB safety limit\n", .{});
        return;
    },
    else => return err,
};
defer allocator.free(decomp);
```

If the stream attempts to emit more bytes than permitted, the decoder halts decoding immediately and returns `error.ExceededOutputLimit` before additional memory is allocated.

### Dictionary Memory Bounds (`dict_size_limit` / `memlimit`)

Block headers declare the dictionary size required by the LZMA2 filter (up to 1.5 GiB in the XZ specification). Rogue or forged headers could otherwise attempt to trigger excessive memory allocations during decoder setup.

```zig
const decomp = try xz.decompress(allocator, untrusted_payload, .{
    .dict_size_limit = 16 * 1024 * 1024, // Allow up to 16 MiB dictionaries
}) catch |err| switch (err) {
    error.ExceededMemoryLimit => {
        std.debug.print("Aborted: block requires dictionary larger than allowed\n", .{});
        return;
    },
    else => return err,
};
```

If the decoded block header requests a dictionary exceeding this limit, the decoder rejects the stream with `error.ExceededMemoryLimit` before dictionary buffer allocation occurs.

---

## 3. Compression Presets & Memory Footprint

`xz.zig` provides standard compression presets (0–9) that scale dictionary sizes and memory usage predictably:

| Preset | Dictionary Size | Description | Recommended Usage |
| :--- | :--- | :--- | :--- |
| `0` | 4 KiB | Fastest / copy chunk store mode | Microcontrollers, extreme memory limits |
| `1` | 64 KiB | Fast compression, tiny memory footprint | Small logs, cache entries |
| `2` | 256 KiB | Lightweight balanced mode | Embedded devices, fast backups |
| `3` | 1 MiB | Moderate compression ratio | Network transfer, quick archiving |
| `4` | 2 MiB | Good ratio, reasonable RAM usage | General-purpose archiving |
| `5` | 4 MiB | Enhanced ratio | Large log files, software distribution |
| `6` | 8 MiB | **Default preset**, optimal balance | Release tarballs, general archives |
| `7` | 16 MiB | High compression ratio | High-ratio backups, release packages |
| `8` | 32 MiB | Very high compression ratio | Static distribution assets |
| `9` | 64 MiB | Maximum ratio mode | Cold storage, archival builds |

You can override the dictionary size explicitly using `.dict_size` in `CompressOptions`:

```zig
const comp = try xz.compress(allocator, data, .{
    .level = 6,
    .dict_size = 4 * 1024 * 1024, // Force 4 MiB dictionary
});
```

---

## 4. Bounded Streaming Pipelines

For files larger than system RAM or infinite network streams, use `compressStream` and `decompressStream`:

```zig
var file = try std.fs.cwd().openFile("archive.xz", .{});
defer file.close();

var reader = file.reader();
var writer = std.io.getStdOut().writer();

try xz.decompressStream(allocator, &reader, &writer, .{
    .dict_size_limit = 32 * 1024 * 1024,
});
```

Streaming I/O operates on bounded internal ring buffers, ensuring memory consumption remains constant regardless of the total file size being processed.

---

## 5. Framing and VLI Integrity

`xz.zig` validates every variable-length integer (VLI) and header framing strictly per the XZ Specification (Section 1.0.4):

- Multi-byte VLIs must not exceed 9 bytes (maximum representable value $2^{63}-1$).
- Padding bytes in Block Headers and Indexes must be strictly `0x00`. Any non-zero padding byte triggers `error.InvalidPadding`.
- Header CRC32 and block check CRC32/CRC64/SHA-256 are validated on every block; corrupted data returns `error.ChecksumMismatch` or `error.CorruptData`.
