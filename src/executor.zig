const std = @import("std");
const sc = @import("screen.zig");

const data_size = @sizeOf(u16);

const Opcode = enum(u8) {
    // Memory
    LOAD = 0x00,
    STORE = 0x01,

    // Math
    ADD = 0x02,
    SUB = 0x03,
    MPL = 0x04,
    DIV = 0x05,

    // Jumps
    JMP = 0x06,
    JMP_P = 0x07,
    JMP_N = 0x08,
    JMP_Z = 0x09,
    JMP_NZ = 0x0A,

    // Functions
    CALL = 0x0B,
    RET = 0x0C,

    // Screen
    CLEAR = 0x0D,
    SHOW = 0x0E,
    PIX_ON = 0x0F,
    PIX_OFF = 0x10,

    // Game
    WAIT = 0x12, // Wait ms
    RECV = 0x13, // Read keyboard
    END = 0x14, // End game

    // Keyboard
    //  Movement
    LFT = 0x15,
    RGT = 0x16,
    UP = 0x17,
    DWN = 0x18,

    //  Actions
    BTA = 0x19,
    BTB = 0x1A,
    BTC = 0x1B,
    BTD = 0x1C,
    SPC = 0x1D,

    // Data
    //  Global
    G_8 = 0x1E,
    G_S8 = 0x1F,
    G_16 = 0x20,
    G_S16 = 0x21,

    //  Local
    L_8 = 0x22,
    L_S8 = 0x23,
    L_16 = 0x24,
    L_S16 = 0x25,

    // Constants
    // LOAD DIR
    // DIR: CONST TYPE
};

fn getAddr(rom_file: *std.Io.File, io: std.Io, pos: u64) !u16 {
    var buff: [data_size]u8 = undefined;

    _ = try rom_file.readPositionalAll(
        io,
        &buff,
        pos,
    );

    return std.mem.readInt(u16, &buff, .little);
}

pub fn gen_vars(rom_file: *std.Io.File, io: std.Io, file_size: u64) !void {
    const const_addr = try getAddr(rom_file, io, file_size - data_size);
    std.log.info("Const addr: {d}", .{const_addr});
}

pub fn exec_game(rom_file: *std.Io.File, io: std.Io, file_size: u64) !void {
    const start_addr = try getAddr(rom_file, io, file_size - data_size * 2);
    std.log.info("Start addr: {d}", .{start_addr});

    var file_pos: u64 = start_addr;

    while (file_pos <= file_size - 1 - data_size * 2) {
        var opbyte: [1]u8 = undefined;
        _ = try rom_file.readPositional(
            io,
            &.{opbyte[0..]},
            file_pos,
        );

        std.log.debug("Opcode: {d}", .{opbyte[0]});
        const opcode: Opcode = @enumFromInt(opbyte[0]);
        switch (opcode) {
            else => {},
        }

        file_pos += 1; // Next dir
    }
}
