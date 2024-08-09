const std = @import("std");
const sdl2 = @import("sdl2");

const PIXEL_SIZE: u8 = 10;
const DISPLAY_WIDTH: u16 = 64;
const DISPLAY_HEIGHT: u16 = 32;
const DISPLAY_SIZE: u16 = DISPLAY_WIDTH * DISPLAY_HEIGHT;

pub const Display = struct {
    pixels: [DISPLAY_SIZE]bool,
    window: sdl2.Window,
    renderer: sdl2.Renderer,

    pub fn render(d: Display) !void {
        try d.renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        try d.renderer.clear();

        d.renderer.present();
    }

    pub fn destroy(d: Display) void {
        d.renderer.destroy();
        d.window.destroy();
    }
};

pub fn init() !Display {
    const windowWidth = DISPLAY_WIDTH * PIXEL_SIZE;
    const windowHeight = DISPLAY_HEIGHT * PIXEL_SIZE;

    const window = try sdl2.createWindow("CHIP-8 Emulator", .{ .centered = {} }, .{ .centered = {} }, windowWidth, windowHeight, .{ .vis = .shown });
    const renderer = try sdl2.createRenderer(window, null, .{ .accelerated = true });
    return Display{ .pixels = [_]bool{false} ** DISPLAY_SIZE, .window = window, .renderer = renderer };
}
