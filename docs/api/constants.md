# Constants & Magic Identifiers

The `xz` package exposes format constants, filter IDs, and integrity check identifiers defined by the XZ container specification.

---

## 1. Stream Magic & Framing

| Constant | Value | Description |
|---|---|---|
| `HEADER_MAGIC` | `"\xFD7zXZ\x00"` | 6-byte magic identifier at the start of every XZ stream |
| `FOOTER_MAGIC` | `"YZ"` (`0x59, 0x5A`) | 2-byte magic identifier at the end of every XZ stream |
| `STREAM_HEADER_SIZE` | `12` bytes | Total byte size of the Stream Header |
| `STREAM_FOOTER_SIZE` | `12` bytes | Total byte size of the Stream Footer |

---

## 2. Filter Identifiers

| Constant | Value | Description |
|---|---|---|
| `FILTER_LZMA2` | `0x21` | LZMA2 compression filter (mandatory last filter) |
| `FILTER_DELTA` | `0x03` | Delta byte distance filter |
| `FILTER_X86_BCJ` | `0x04` | x86 / x86_64 BCJ branch-call-jump address translator |

---

## 3. Check Type Identifiers

| Constant | ID | Check Field Size | Algorithm |
|---|---|---|---|
| `CHECK_NONE` | `0x00` | 0 bytes | No integrity check |
| `CHECK_CRC32` | `0x01` | 4 bytes | IEEE 802.3 CRC32 |
| `CHECK_CRC64` | `0x04` | 8 bytes | ECMA-182 reversed polynomial CRC64 |
| `CHECK_SHA256` | `0x0A` | 32 bytes | Cryptographic SHA-256 |

---

## 4. Variable-Length Integer (VLI) Limits

| Constant | Value | Description |
|---|---|---|
| `VLI_MAX` | `9223372036854775807` ($2^{63}-1$) | Maximum allowed VLI value |
| `VLI_BYTES_MAX` | `9` bytes | Maximum serialized byte length of a single VLI |

---

## 5. Package Information

| Constant | Value | Description |
|---|---|---|
| `version` | `"0.0.1"` | Library version string |
