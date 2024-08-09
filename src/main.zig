const std = @import("std");
const sdl = @import("sdl2");
const Display = @import("Display.zig");

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
