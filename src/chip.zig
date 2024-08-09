const std = @import("std");

const Chip8 = struct {
    memory: [0x1000]u8,
    display: [64][32]bool,
    pc: u16,
    index_register: u16,
    stack: std.ArrayList(u16),
    delay_timer: u8,
    sound_timer: u8,
    variable_registers: [16]u8
};
