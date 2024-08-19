const std = @import("std");
const sdl = @import("sdl2");
const Display = @import("Display.zig");
const Emulator = @import("Emulator.zig");

pub fn main() !void {
    try sdl.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer sdl.quit();

    var display = Display{};

    try display.init();
    defer display.destroy();

    var data: [0x1000]u8 = [_]u8{0} ** 0x1000;

    // Open the file from the current working directory
    var file = try std.fs.cwd().openFile("files/test_opcode.ch8", .{ .mode = .read_only });
    defer file.close();

    const f_reader = file.reader();

    const read_bytes = try f_reader.readAll(&data);

    var emu = Emulator{};
    emu.init(&display, data[0..read_bytes]);

    mainLoop: while (true) {
        while (sdl.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
        }

        std.time.sleep(10_000_000);

        const instruction = try emu.fetch();

        try emu.decodeAndExecute(instruction);

        try display.render();
    }

    emu.deinit();
}
