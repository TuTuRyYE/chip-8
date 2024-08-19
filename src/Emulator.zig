const std = @import("std");
const Display = @import("Display.zig");

const Emulator = @This();

const PROGRAM_MEMORY_ADDRESS = 0x200;

memory: [0x1000]u8 = [_]u8{0} ** 0x1000,
display: *Display = undefined,
pc: u16 = PROGRAM_MEMORY_ADDRESS,
index_register: u16 = 0,
stack: std.ArrayList(u16) = undefined,
set_value_before_shift: bool = true,

delay_timer: u8 = 0,
sound_timer: u8 = 0,
registers: [16]u8 = [_]u8{0} ** 16,

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
    emu.stack = std.ArrayList(u16).init(std.heap.page_allocator);
}

pub fn deinit(emu: *Emulator) void {
    emu.stack.deinit();
}

const FONT_START_ADDRESS: u16 = 0x050; //First address for fonts
const FONT_STOP_ADDRESS: u16 = 0x09F; //Last address for fonts
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

pub fn decodeAndExecute(emu: *Emulator, inst: u16) error{ UnknownInstruction, OutOfMemory, MustBeImplemented }!void {
    std.debug.print("\nInstruction: {X} => ", .{inst});

    const address: u12 = @truncate(inst & 0x0FFF);
    const vx: u4 = @truncate((inst & 0x0F00) >> 8);
    const vy: u4 = @truncate((inst & 0x00F0) >> 4);
    const byte: u8 = @truncate(inst & 0x00FF);
    const nibble: u4 = @truncate(inst & 0x000F);

    switch (inst >> 12) {
        0x0 => {
            switch (inst & 0xFF) {
                0xE0 => {
                    // clear screen
                    emu.display.pixels = [_]u1{0} ** Display.SIZE;
                    std.debug.print("clear screen", .{});
                },
                0xEE => {
                    //return subroutine
                    const subroutine = emu.stack.pop();
                    emu.pc = subroutine;
                    std.debug.print("return subroutine {X}", .{subroutine});
                },
                else => return error.UnknownInstruction,
            }
        },
        0x1 => {
            // jump to
            emu.pc = address;
            std.debug.print("jump to address {X}", .{address});
        },
        0x2 => {
            // call subroutine
            try emu.stack.append(emu.pc);
            std.debug.print("calling subroutine at {X}, from {X}", .{ address, emu.pc });
            emu.pc = address;
        },
        0x3 => {
            if (emu.registers[vx] == byte) {
                emu.pc += 2;
            }
            std.debug.print("if register {X} equal value {X} then skip one instruction", .{ vx, byte });
        },
        0x4 => {
            if (emu.registers[vx] != byte) {
                emu.pc += 2;
            }
            std.debug.print("if register {X} is not equal value {X} then skip one instruction", .{ vx, byte });
        },
        0x5 => {
            if (emu.registers[vx] == emu.registers[vy]) {
                emu.pc += 2;
            }

            std.debug.print("if register {X} equal register {X} then skip one instruction", .{ vx, vy });
        },
        0x6 => {
            emu.registers[vx] = byte;
            std.debug.print("set register {X} to value {X}", .{ vx, byte });
        },
        0x7 => {
            const res = @addWithOverflow(emu.registers[vx], byte);
            emu.registers[vx] = res[0];
            std.debug.print("add value {X} to register {X}", .{ vx, byte });
        },
        0x8 => {
            switch (inst & 0xF) {
                0 => {
                    emu.registers[vx] = emu.registers[vy];
                    std.debug.print("store vy {X} into vx {X}", .{ vy, vx });
                },
                1 => {
                    emu.registers[vx] = emu.registers[vx] | emu.registers[vy];
                    std.debug.print("set vx to vx {X} or vy {X}", .{ vx, vy });
                },
                2 => {
                    emu.registers[vx] = emu.registers[vx] & emu.registers[vy];
                    std.debug.print("set vx to vx {X} and vy {X}", .{ vx, vy });
                },
                3 => {
                    emu.registers[vx] = emu.registers[vx] ^ emu.registers[vy];
                    std.debug.print("set vx to vx {X} xor vy {X}", .{ vx, vy });
                },
                4 => {
                    const res: struct { u8, u1 } = @addWithOverflow(emu.registers[vx], emu.registers[vy]);
                    emu.registers[vx] = res[0];
                    emu.registers[0xF] = res[1];
                    std.debug.print("add vy {X} to vx {X} and set vf to carry {X} value", .{ vy, vx, res[1] });
                },
                5 => {
                    const res: struct { u8, u1 } = @subWithOverflow(emu.registers[vx], emu.registers[vy]);
                    emu.registers[vx] = res[0];
                    emu.registers[0xF] = if (res[1] == 1) 0 else 1;
                    std.debug.print("substract vy {X} to vx {X} into vx, with borrow {X}", .{ vy, vx, emu.registers[0xF] });
                },
                6 => {
                    const outBit = emu.registers[vy] & 1;

                    emu.registers[vx] = emu.registers[vy] >> 1;
                    emu.registers[0xF] = outBit;
                    std.debug.print("store vy {X} shifted right to vx {X} with outbit {X}", .{ vy, vx, emu.registers[0xF] });
                },
                7 => {
                    const res: struct { u8, u1 } = @subWithOverflow(emu.registers[vy], emu.registers[vx]);
                    emu.registers[vx] = res[0];
                    emu.registers[0xF] = if (res[1] == 1) 0 else 1;
                    std.debug.print("substract vx {X} to vy {X} into vx, with borrow {X}", .{ vx, vy, emu.registers[0xF] });
                },
                0xE => {
                    const outBit = (emu.registers[vy] & 0x80) >> 7;

                    emu.registers[vx] = emu.registers[vy] << 1;
                    emu.registers[0xF] = outBit;
                    std.debug.print("store vy {X} shifted left to vx {X} with outbit {X}", .{ vy, vx, emu.registers[0xF] });
                },
                else => return error.UnknownInstruction,
            }
        },
        0x9 => {
            if (emu.registers[vx] != emu.registers[vy]) {
                emu.pc += 2;
            }

            std.debug.print("if register {X} not equal register {X} then skip one instruction", .{ vx, vy });
        },
        0xA => {
            emu.index_register = address;
            std.debug.print("store address {X} in index_register", .{address});
        },
        0xB => {
            emu.pc = address + emu.registers[0];
            std.debug.print("jump to address {X} + V0 {X}", .{ address, emu.registers[0] });
        },
        0xC => {
            const rand = std.crypto.random.int(u8);
            emu.registers[vx] = byte & rand;
            std.debug.print("set vx {X} to a random number of mask {X}", .{ vx, byte });
        },
        0xD => {
            const spriteHeight = nibble;
            const x = emu.registers[vx] & (Display.WIDTH - 1); //thanks 0-indexing
            const y = emu.registers[vy] & (Display.HEIGHT - 1);
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
                emu.registers[0xF] = 1;
            }
        },
        0xE => {
            return error.MustBeImplemented;
        },
        0xF => {
            switch (inst & 0xFF) {
                0x07 => {
                    emu.registers[vx] = emu.delay_timer;
                },
                0x0A => {
                    //get key
                },
                0x15 => {
                    emu.delay_timer = emu.registers[vx];
                },
                0x18 => {
                    emu.sound_timer = emu.registers[vx];
                },
                0x1E => {
                    emu.index_register += emu.registers[vx];
                },
                0x29 => {
                    const font: u4 = @truncate(emu.registers[vx] & 0xF);
                    emu.index_register = FONT_START_ADDRESS + font * 5;
                },
                0x33 => {
                    const value = emu.registers[vx];
                    const hundred = value / 100;
                    const tens = (value - hundred * 100) / 10;
                    const units = value % 10;
                    emu.memory[emu.index_register] = hundred;
                    emu.memory[emu.index_register + 1] = tens;
                    emu.memory[emu.index_register + 2] = units;
                },
                0x55 => {
                    for (0..vx + 1) |i| {
                        emu.memory[emu.index_register + i] = emu.registers[i];
                    }
                    emu.index_register = emu.index_register + vx + 1;
                },
                0x65 => {
                    for (0..vx + 1) |i| {
                        emu.registers[i] = emu.memory[emu.index_register + i];
                    }
                    emu.index_register = emu.index_register + vx + 1;
                },
                else => return error.UnknownInstruction,
            }
        },
        else => {
            return error.UnknownInstruction;
        },
    }
}
