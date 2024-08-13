const std = @import("std");
const sdl = @import("sdl2");
const Display = @import("Display.zig");
const Emulator = @import("emulator.zig");

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

    var emu = Emulator{};
    emu.init(&display);

    mainLoop: while (true) {
        while (sdl.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
        }

        try display.render();
    }
}
