const std = @import("std");
const sdl2 = @import("sdl2");

pub const Display = @This();

pub const PIXEL_SIZE: u8 = 10;
pub const WIDTH: usize = 64;
pub const HEIGHT: usize = 32;
const SIZE: usize = WIDTH * HEIGHT;

pixels: [SIZE]bool = [_]bool{false} ** SIZE,

window: sdl2.Window = undefined,
renderer: sdl2.Renderer = undefined,

pub fn init(d: *Display) !void {
    const windowWidth = WIDTH * PIXEL_SIZE;
    const windowHeight = HEIGHT * PIXEL_SIZE;

    d.window = try sdl2.createWindow("CHIP-8 Emulator", .{ .centered = {} }, .{ .centered = {} }, windowWidth, windowHeight, .{ .vis = .shown });
    d.renderer = try sdl2.createRenderer(d.window, null, .{ .accelerated = true });
}

pub fn destroy(d: *Display) void {
    d.renderer.destroy();
    d.window.destroy();
}

pub fn render(d: *Display) !void {
    var i: usize = 0;
    var color = sdl2.Color.black;
    while (i < SIZE) {
        color = if (d.pixels[i]) sdl2.Color.white else sdl2.Color.black;
        try d.renderer.setColor(color);

        const x = i % WIDTH;
        const y = (i - x) / WIDTH;

        const pixel: sdl2.Rectangle = .{
            .x = @intCast(x * PIXEL_SIZE),
            .y = @intCast(y * PIXEL_SIZE),
            .height = PIXEL_SIZE,
            .width = PIXEL_SIZE,
        };
        try d.renderer.fillRect(pixel);

        i += 1;
    }

    d.renderer.present();
}
