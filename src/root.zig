pub const xz = @import("xz.zig");
pub const compress = xz.compress;
pub const compressInto = xz.compressInto;
pub const decompress = xz.decompress;
pub const decompressInto = xz.decompressInto;
pub const compressStream = xz.compressStream;
pub const decompressStream = xz.decompressStream;
pub const isXzStream = xz.isXzStream;
pub const maxCompressedSize = xz.maxCompressedSize;
pub const CheckType = xz.CheckType;
pub const CompressOptions = xz.CompressOptions;
pub const DecompressOptions = xz.DecompressOptions;
pub const Error = xz.Error;
pub const crc32 = xz.crc32;
pub const crc64 = xz.crc64;
pub const sha256 = xz.sha256;
pub const lzma2 = xz.lzma2;

test {
    _ = @import("xz.zig");
}
