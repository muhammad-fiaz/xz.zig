# Security Policy

## Supported Versions

| Version | Supported          |
| :---    | :---               |
| 0.0.x   | :white_check_mark: |

## Reporting a Vulnerability

Because compression container libraries frequently process untrusted input from network sockets, archives, and external storage, all decoders and parsers in `xz.zig` are designed to fail safely rather than crash, leak memory, or execute out-of-bounds operations.

**Please do NOT report security vulnerabilities through public GitHub issues or discussions.**

If you discover a security vulnerability, memory safety bug, buffer overrun, decompression bomb vector, or denial-of-service issue (such as an unhandled panic, integer overflow, or infinite loop on malformed input), please report it privately:

- **Email**: [contact@muhammadfiaz.com](mailto:contact@muhammadfiaz.com)
- **Subject**: `[SECURITY] xz.zig Vulnerability Report`

Please include in your report:
1. A clear description of the vulnerability and its potential impact.
2. A minimal reproducible example or test payload (e.g., malformed XZ container stream).
3. The affected version of `xz.zig`, Zig compiler version, and target architecture / OS.
4. Any proposed patches or mitigations if available.

Reports will be reviewed and investigated by the maintainers. Confirmed vulnerabilities and fixes will be coordinated and published through GitHub Security Advisories and release notes.

## Resource Exhaustion & Decompression Bombs

XZ containers encapsulate LZMA2 compressed blocks and optional filter stages. Malicious payloads ("decompression bombs" or "tarbombs") can be crafted to expand into petabytes of uncompressed output from small inputs.

When handling untrusted data:
- **Configure `max_output_size`**: Specify `DecompressOptions.max_output_size` to enforce an upper bound on decompressed byte count across the stream. If decompression exceeds this threshold, the operation terminates immediately with `error.ExceededOutputLimit`.
- **Configure `dict_size_limit` / `memlimit`**: Restrict the maximum permitted dictionary size in `DecompressOptions` to prevent rogue headers from forcing excessive memory consumption (`error.ExceededMemoryLimit`).
- **Use Caller-Provided Buffers**: For constrained or embedded environments, use `decompressInto` with fixed-size destination slices. If the output exceeds buffer capacity, the function returns `error.OutputTooSmall` without allocating heap memory.

## Format Validation vs. Security Guarantees

The decoder strictly validates container and block framing:
- Stream header magic (`FD 37 7A 58 5A 00`) and stream footer magic (`59 5A`) are verified.
- CRC32, CRC64, and SHA-256 integrity checks are computed and validated across every block. Mismatches return `error.ChecksumMismatch`.
- Stream flags, backward size calculations, index padding, and block alignment are validated against the XZ file format specification (Version 1.0.4).
- Unsupported check types return `error.UnsupportedCheck`.
- Filter IDs and properties are checked, returning `error.UnsupportedFilter` or `error.InvalidFilterProperties` on unknown or malformed filters.

However, container format validation alone cannot verify the semantic safety of decompressed content or prevent application-level denial of service. Applications must enforce appropriate output size limits and resource bounds when decompressing untrusted inputs.
