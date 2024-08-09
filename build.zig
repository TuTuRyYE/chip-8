const std = @import("std");
const sdl = @import("sdl"); // Replace with the actual name in your build.zig.zon

pub fn build(b: *std.Build) !void {
    // Determine compilation target
    const target = b.standardTargetOptions(.{});

    // Create a new instance of the SDL2 Sdk
    // Specifiy dependency name explicitly if necessary (use sdl by default)
    const sdk = sdl.init(b, .{});

    // Create executable for our example
    const exe = b.addExecutable(.{
        .name = "chip_8",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
    });

    sdk.link(exe, .dynamic, sdl.Library.SDL2); // link SDL2 as a shared library

    exe.root_module.addImport("sdl2", sdk.getWrapperModule());

    // Install the executable into the prefix when invoking "zig build"
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
