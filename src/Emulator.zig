const std = @import("std");
const Display = @import("Display.zig");

const Emulator = @This();

memory: [0x1000]u8 = [_]u8{0} ** 0x1000,
display: *Display = undefined,
//pc: u16,
//index_register: u16,
//stack: std.ArrayList(u16),
//delay_timer: u8,
//sound_timer: u8,
//variable_registers: [16]u8,

pub fn init(emu: *Emulator, display: *Display) void {
    for (FONTS, 0..) |font, i| {
        for (font, 0..) |value, j| {
            emu.memory[FONT_START_ADDRESS + i * font.len + j] = value;
        }
    }

    emu.display = display;

    emu.display.pixels[13] = true;
    emu.display.pixels[14] = true;
}

const FONT_START_ADDRESS = 0x050; //First address for fonts
const FONT_STOP_ADDRESS = 0x09F; //Last address for fonts
const FONTS = [16][5]u8{
    [5]u8{ 0xF0, 0x90, 0x90, 0x90, 0xF0 }, // 0
    [5]u8{ 0x20, 0x60, 0x20, 0x20, 0x70 }, // 1
    [5]u8{ 0xF0, 0x10, 0xF0, 0x80, 0xF0 }, // 2
    [5]u8{ 0xF0, 0x10, 0xF0, 0x10, 0xF0 }, // 3
    [5]u8{ 0x90, 0x90, 0xF0, 0x10, 0x10 }, // 4
    [5]u8{ 0xF0, 0x80, 0xF0, 0x10, 0xF0 }, // 5
    [5]u8{ 0xF0, 0x80, 0xF0, 0x90, 0xF0 }, // 6
    [5]u8{ 0xF0, 0x10, 0x20, 0x40, 0x40 }, // 7
    [5]u8{ 0xF0, 0x90, 0xF0, 0x90, 0xF0 }, // 8
    [5]u8{ 0xF0, 0x90, 0xF0, 0x10, 0xF0 }, // 9
    [5]u8{ 0xF0, 0x90, 0xF0, 0x90, 0x90 }, // A
    [5]u8{ 0xF0, 0x90, 0x90, 0x90, 0xF0 }, // B
    [5]u8{ 0xF0, 0x80, 0x80, 0x80, 0xF0 }, // C
    [5]u8{ 0xE0, 0x90, 0x90, 0x90, 0xE0 }, // D
    [5]u8{ 0xF0, 0x80, 0xF0, 0x80, 0xF0 }, // E
    [5]u8{ 0xF0, 0x80, 0xF0, 0x80, 0x80 }, // F
};

test "font do not overflow their space" {
    const emu = Emulator.init();

    try std.testing.expect(emu.memory[FONT_STOP_ADDRESS] != 0);
    try std.testing.expect(emu.memory[FONT_STOP_ADDRESS + 1] == 0);
}
