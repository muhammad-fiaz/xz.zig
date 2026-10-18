# XZ Container Format & Framing Specification

The `.xz` file format is a modern, modular container format designed to provide high-ratio data compression, integrity verification, multi-block streaming, and random-access seeking.

---

## 1. Stream Overview

An XZ file consists of one or more concatenated **Streams**. Each stream has the following sequential structure:

```text
+---------------+-----------+-------+---------------+
| Stream Header | Block ... | Index | Stream Footer |
+---------------+-----------+-------+---------------+
```

- **Stream Header** (12 bytes): Validates file type and declares the check algorithm.
- **Blocks** (variable length): Contain one or more independent compressed blocks, each with optional filter chains, padding, and integrity checks.
- **Index** (variable length): Summarizes unpadded block sizes and uncompressed sizes for backward seeking and integrity verification.
- **Stream Footer** (12 bytes): Confirms index size, repeats stream flags, and verifies overall stream integrity.

---

## 2. Stream Header (12 Bytes)

```text
+-------------------+--------------+--------------+
| Header Magic (6B) | Stream Flags | CRC32 Check  |
| FD 37 7A 58 5A 00 |   (2 bytes)  |  (4 bytes)   |
+-------------------+--------------+--------------+
```

1. **Header Magic**: Exact 6-byte sequence `0xFD, '7', 'z', 'X', 'Z', 0x00`.
2. **Stream Flags**: 16-bit little-endian integer:
   - Bits 0..3: **Check Type ID**:
     - `0x00`: None (no check bytes)
     - `0x01`: CRC32 (4 bytes, IEEE 802.3)
     - `0x04`: CRC64 (8 bytes, ECMA-182)
     - `0x0A`: SHA-256 (32 bytes)
   - Bits 4..15: Reserved (MUST be 0).
3. **CRC32**: Little-endian CRC32 calculated over the 2-byte Stream Flags.

---

## 3. Block Framing

Each Block contains the payload along with metadata and verification fields:

```text
+==============+=================+===============+=======+
| Block Header | Compressed Data | Block Padding | Check |
+==============+=================+===============+=======+
```

### 3.1. Block Header

The Block Header is padded with null bytes to a multiple of 4 bytes:

```text
+-------------+-------------+------------------+---------------+-------------+
| Header Size | Block Flags | Filter Chain ... | Header Padded | CRC32 Check |
|   (1 byte)  |   (1 byte)  |    (variable)    |   (0-3 nulls) |  (4 bytes)  |
+-------------+-------------+------------------+---------------+-------------+
```

1. **Block Header Size**: Encoded as `(real_header_size / 4) - 1`. Minimum real size is 8 bytes (`encoded = 1`).
2. **Block Flags**:
   - Bits 0..1: Number of filters minus 1 (`0` = 1 filter, `3` = 4 filters).
   - Bits 2..5: Reserved (MUST be 0).
   - Bit 6: Compressed Size present in header.
   - Bit 7: Uncompressed Size present in header.
3. **Filter Chain**: A sequence of 1 to 4 filter definitions. The last filter in the chain MUST be LZMA2 (`0x21`). Optional non-last filters include Delta (`0x03`) and x86 BCJ (`0x04`).
4. **Header Padding**: 0 to 3 null bytes to align the header to a 4-byte boundary.
5. **CRC32**: Calculated over all preceding bytes of the Block Header.

### 3.2. Compressed Data & Padding

- **Compressed Data**: Raw encoded stream produced by the filter chain (e.g. raw LZMA2 chunks).
- **Block Padding**: 0 to 3 null bytes added so that `Compressed Data` size is a multiple of 4 bytes.
- **Check**: Integrity check computed over the original uncompressed data.

---

## 4. The Index

The Index appears immediately after the last Block:

```text
+-----------------+-------------------+-----------------+---------------+-------------+
| Index Indicator | Number of Records | Record List ... | Index Padding | CRC32 Check |
|   0x00 (1 byte) |       (VLI)       |    (VLIs ...)   |  (0-3 nulls)  |  (4 bytes)  |
+-----------------+-------------------+-----------------+---------------+-------------+
```

- **Index Indicator**: A single `0x00` byte distinguishing the Index from a Block Header.
- **Number of Records**: Variable-Length Integer declaring total block count.
- **Record List**: For each block:
  - `Unpadded Size` (VLI): Size of `Block Header + Compressed Data + Check`.
  - `Uncompressed Size` (VLI): Original byte length.
- **Index Padding**: 0 to 3 null bytes aligning the Index to 4 bytes.
- **CRC32**: Calculated over the Index from Indicator through Index Padding.

---

## 5. Stream Footer (12 Bytes)

```text
+-------------+---------------+--------------+-------------------+
| CRC32 Check | Backward Size | Stream Flags | Footer Magic (2B) |
|  (4 bytes)  |   (4 bytes)   |  (2 bytes)   |       59 5A       |
+-------------+---------------+--------------+-------------------+
```

- **CRC32**: Computed over `Backward Size + Stream Flags`.
- **Backward Size**: Little-endian 32-bit integer encoding `(Index_size / 4) - 1`. Allows decoders seeking backward to immediately locate the Index.
- **Stream Flags**: MUST match the Stream Flags in the Stream Header.
- **Footer Magic**: `0x59, 0x5A` ('Y', 'Z').

---

## 6. Comparison: Raw LZMA2 vs Legacy `.lzma` vs `.xz`

| Attribute | Raw LZMA2 | Legacy `.lzma` | `.xz` Container |
|---|---|---|---|
| **Magic Bytes** | None | None | `FD 37 7A 58 5A 00` |
| **Integrity Checks** | None | None | None, CRC32, CRC64, SHA-256 |
| **Multi-Block Seeking** | No | No | Yes (via Index & Backward Size) |
| **Filter Chains** | LZMA2 only | LZMA1 only | LZMA2 + Delta + BCJ |
| **End of Stream** | Control byte `0x00` | Optional EOS or 13B header size | Stream Footer |
| **Responsible Package** | [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig) | [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig) | [`xz.zig`](https://github.com/muhammad-fiaz/xz.zig) |
