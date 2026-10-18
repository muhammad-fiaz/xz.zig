const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Resolve lzma2 package dependency
    const lzma2_dep = b.dependency("lzma2", .{
        .target = target,
        .optimize = optimize,
    });
    const lzma2_mod = lzma2_dep.module("lzma2");

    // XZ module export: @import("xz")
    const xz_mod = b.addModule("xz", .{
        .root_source_file = b.path("src/xz.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
        .imports = &.{
            .{ .name = "lzma2", .module = lzma2_mod },
        },
    });

    // Static library artifact (libxz)
    const lib = b.addLibrary(.{
        .name = "xz",
        .root_module = xz_mod,
    });
    b.installArtifact(lib);

    // Main test step
    const test_step = b.step("test", "Run all tests");
    const xz_tests = b.addTest(.{
        .root_module = xz_mod,
    });
    const run_xz_tests = b.addRunArtifact(xz_tests);
    test_step.dependOn(&run_xz_tests.step);

    // Fuzz testing step (`zig build fuzz`)
    const fuzz_step = b.step("fuzz", "Run fuzz and edge-case validation suite");
    fuzz_step.dependOn(&run_xz_tests.step);

    // Check step for CI
    const check_step = b.step("check", "Check compilation of library, tests, and examples");
    check_step.dependOn(&lib.step);
    check_step.dependOn(&xz_tests.step);

    // Documentation step: zig build docs
    const docs_step = b.step("docs", "Generate HTML documentation");
    const docs_obj = b.addObject(.{
        .name = "xz",
        .root_module = xz_mod,
    });
    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs_obj.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);

    // Standalone examples
    const examples = [_]struct { name: []const u8, file: []const u8 }{
        .{ .name = "basic_compression", .file = "examples/basic_compression.zig" },
        .{ .name = "caller_buffer", .file = "examples/caller_buffer.zig" },
        .{ .name = "streaming_pipeline", .file = "examples/streaming_pipeline.zig" },
        .{ .name = "checksum_types", .file = "examples/checksum_types.zig" },
        .{ .name = "filter_chains", .file = "examples/filter_chains.zig" },
        .{ .name = "error_handling", .file = "examples/error_handling.zig" },
    };

    const run_all = b.step("run-all-examples", "Run all examples");

    inline for (examples) |example| {
        const run_step = b.step(
            "run-" ++ example.name,
            "Run " ++ example.name ++ " example",
        );

        const exe = b.addExecutable(.{
            .name = "example-" ++ example.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(example.file),
                .target = target,
                .optimize = optimize,
                .link_libc = false,
                .imports = &.{
                    .{ .name = "xz", .module = xz_mod },
                    .{ .name = "lzma2", .module = lzma2_mod },
                },
            }),
        });

        check_step.dependOn(&exe.step);
        const run_exe = b.addRunArtifact(exe);
        run_step.dependOn(&run_exe.step);
        run_all.dependOn(&run_exe.step);
    }
}
