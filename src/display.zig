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

pub fn render(d: Display) !void {
    try d.renderer.setColorRGB(0xF7, 0xA4, 0x1D);
    try d.renderer.clear();

    d.renderer.present();
}
