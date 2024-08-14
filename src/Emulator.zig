const std = @import("std");
const Display = @import("Display.zig");

const Emulator = @This();

const PROGRAM_MEMORY_ADDRESS = 0x200;

memory: [0x1000]u8 = [_]u8{0} ** 0x1000,
display: *Display = undefined,
pc: u16 = PROGRAM_MEMORY_ADDRESS,
index_register: u16 = 0,
//stack: std.ArrayList(u16),
//
//delay_timer: u8,
//sound_timer: u8,
variable_registers: [16]u8 = [_]u8{0} ** 16,

pub fn init(emu: *Emulator, display: *Display, program: []u8) void {
    for (FONTS, 0..) |font, i| {
        for (font, 0..) |value, j| {
            emu.memory[FONT_START_ADDRESS + i * font.len + j] = value;
        }
    }

    for (program, 0..) |byte, i| {
        emu.memory[PROGRAM_MEMORY_ADDRESS + i] = byte;
    }

    emu.display = display;
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

pub fn fetch(emu: *Emulator) error{MemoryOutOfBound}!u16 {
    if (emu.pc >= 0x1000 - 1) {
        return error.MemoryOutOfBound;
    }
    const inst: u16 = (@as(u16, emu.memory[emu.pc]) << 8) + emu.memory[emu.pc + 1];
    emu.pc += 2;

    return inst;
}

pub fn decodeAndExecute(emu: *Emulator, inst: u16) error{UnknownInstruction}!void {
    std.debug.print("\nInstruction: {X} => ", .{inst});

    switch (inst >> 12) {
        0x0 => { // clear screen
            emu.display.pixels = [_]u1{0} ** Display.SIZE;
            std.debug.print("clear screen", .{});
        },
        0x1 => {
            emu.pc = inst & 0x0FFF;
            std.debug.print("jump to {X}", .{emu.pc});
        },
        0x6 => {
            const register = (inst & 0x0F00) >> 8;
            const value: u8 = @truncate(inst & 0x00FF);
            emu.variable_registers[register] = value;
            std.debug.print("set register {X} to value {X}", .{ register, value });
        },
        0x7 => {
            const register = (inst & 0x0F00) >> 8;
            const value: u8 = @truncate(inst & 0x00FF);
            emu.variable_registers[register] += value;
            std.debug.print("add value {X} to register {X}", .{ value, register });
        },
        0xA => {
            emu.index_register = inst & 0x0FFF;
            std.debug.print("set index_register to {X}", .{emu.index_register});
        },
        0xD => {
            const spriteHeight = inst & 0x000F;
            const x = emu.variable_registers[(inst & 0x0F00) >> 8] & (Display.WIDTH - 1); //thanks 0-indexing
            const y = emu.variable_registers[(inst & 0x00F0) >> 4] & (Display.HEIGHT - 1);
            const spriteIndex = emu.index_register;

            std.debug.print("draw sprite {X} with height {d} at position (x, y) = ({d}, {d})", .{ spriteIndex, spriteHeight, x, y });

            var turnedOffPixel = false;
            var i: usize = 0;
            while (i < spriteHeight and i + y < Display.HEIGHT) {
                const spriteLine = emu.memory[spriteIndex + i];
                var j: u3 = 0;
                while (j <= 7 and j + x < Display.WIDTH) {
                    const bit: u1 = @truncate((spriteLine >> (7 - j)) & 1);
                    emu.display.pixels[x + j + (i + y) * Display.WIDTH] = emu.display.pixels[x + j + (i + y) * Display.WIDTH] ^ bit;

                    if (bit == 1 and emu.display.pixels[x + j + (i + y) * Display.WIDTH] == 0) {
                        turnedOffPixel = true;
                    }

                    const res: struct { u3, u1 } = @addWithOverflow(j, 1);
                    if (res[1] == 1) {
                        break;
                    }

                    j = res[0];
                }

                i += 1;
            }
            if (turnedOffPixel) {
                emu.variable_registers[0xF] = 1;
            }
        },
        else => {
            return error.UnknownInstruction;
        },
    }
}
