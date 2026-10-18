# Installation & Build Integration

`xz.zig` is a production-ready, pure native Zig package designed for **Zig 0.17.0 or later**. It has zero external C dependencies, requires no system `liblzma`, delivers 100% bit-perfect cross-tool interoperability with official XZ Utils (`xz.exe` v5.8.1) and 7-Zip (`7z.exe` v26.03), and automatically manages its dependency on [`lzma2.zig`](https://github.com/muhammad-fiaz/lzma2.zig).

---

## 1. Requirements

- **Zig Compiler**: Version `0.17.0 or later` (required).
- **Supported Operating Systems**: Linux, Windows, macOS, FreeBSD, NetBSD, and bare-metal targets supported by Zig.

---

## 2. Adding to `build.zig.zon`

You can fetch and record the package dependency automatically with `zig fetch`. The **recommended** method for production applications is to pin to the tagged stable release:

```bash
# Recommended: Tagged stable release (0.0.1)
zig fetch --save https://github.com/muhammad-fiaz/xz.zig/archive/refs/tags/0.0.1.tar.gz

# Alternative: Latest development build (main branch)
zig fetch --save git+https://github.com/muhammad-fiaz/xz.zig.git
```

Alternatively, you can manually add `xz` to your `build.zig.zon`:

```zig
.{
    .name = .my_app,
    .version = "0.1.0",
    .dependencies = .{
        .xz = .{
            .url = "https://github.com/muhammad-fiaz/xz.zig/archive/refs/tags/0.0.1.tar.gz",
            .hash = "...", // populated automatically by zig fetch
        },
    },
    .paths = .{ "" },
}
```

---

## 3. Exposing the Module in `build.zig`

In your consumer `build.zig`, import the dependency and add it to your root module:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Resolve xz dependency
    const xz_dep = b.dependency("xz", .{
        .target = target,
        .optimize = optimize,
    });

    // 2. Create your executable or library
    const exe = b.addExecutable(.{
        .name = "my_app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // 3. Add xz import
    exe.root_module.addImport("xz", xz_dep.module("xz"));

    b.installArtifact(exe);
}
```

---

## 4. Importing in Source Code

Once wired into your build configuration, import `xz` in your source files:

```zig
const std = @import("std");
const xz = @import("xz");

pub fn main() !void {
    const data = "Test string for XZ container compression";
    const compressed = try xz.compress(std.heap.page_allocator, data, .{ .check = .crc64 });
    defer std.heap.page_allocator.free(compressed);
}
```
