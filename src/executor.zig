const std = @import("std");
const sc = @import("screen.zig");

pub const data_size = @sizeOf(u16);
pub const ddata_size = 50;

const Opcode = enum(u8) {
    // Memory
    LOAD = 0x00, // If the load dir is higher than the number of vars, it means we have to load a const
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
    WAIT = 0x11, // Wait ms
    RECV = 0x12, // Read keyboard
    END = 0x13, // End game

    // Keyboard
    //  Movement
    LFT = 0x14,
    RGT = 0x15,
    UP = 0x16,
    DWN = 0x17,

    //  Actions
    BTA = 0x18,
    BTB = 0x19,
    BTC = 0x1A,
    BTD = 0x1B,
    SPC = 0x1C,

    // Data
    V_8 = 0x1D,
    V_S8 = 0x1E,
    V_16 = 0x2F,
    V_S16 = 0x20,

    // Constants
    // LOAD DIR
    // DIR: CONST TYPE | DATA
};

pub fn read2B(rom_file: *std.Io.File, io: std.Io, pos: *u64) !u16 {
    var buff: [2]u8 = undefined;

    _ = try rom_file.readPositionalAll(
        io,
        &buff,
        pos.*,
    );

    pos.* += 2;
    return std.mem.readInt(u16, &buff, .little);
}

pub fn read1B(rom_file: *std.Io.File, io: std.Io, pos: *u64) !u8 {
    var buff: [1]u8 = undefined;

    _ = try rom_file.readPositionalAll(
        io,
        &buff,
        pos.*,
    );

    pos.* += 1;
    return std.mem.readInt(u8, &buff, .little);
}

pub fn exec_game(rom_file: *std.Io.File, io: std.Io, file_size: u64, start_addr: u64) !void {
    var file_pos: u64 = start_addr;

    // Generate screen
    var screenBuffer: [sc.screenWidth][sc.screenHeight]bool = undefined;
    sc.clearScreen(&screenBuffer);

    // Read instructions
    while (file_pos <= file_size - 1 - data_size * 2) {
        const word = try read1B(rom_file, io, &file_pos);
        const opcode: Opcode = @enumFromInt(word);
        std.log.debug("Opcode: 0x{X:0>2}", .{opcode});

        switch (opcode) {
            // Memory
            Opcode.LOAD => {},
            Opcode.STORE => {},

            // Math
            Opcode.ADD => {},
            Opcode.SUB => {},
            Opcode.MPL => {},
            Opcode.DIV => {},

            // Jumps
            Opcode.JMP => {},
            Opcode.JMP_P => {},
            Opcode.JMP_N => {},
            Opcode.JMP_Z => {},
            Opcode.JMP_NZ => {},

            // Screen
            Opcode.CLEAR => sc.clearScreen(&screenBuffer),
            Opcode.SHOW => sc.showScreen(&screenBuffer),
            Opcode.PIX_ON, Opcode.PIX_OFF => {
                const posx = try read1B(rom_file, io, &file_pos);
                const posy = try read1B(rom_file, io, &file_pos);
                std.log.info("X: {d} | Y: {d}", .{ posx, posy });
                sc.setPixel(&screenBuffer, posx, posy, opcode == Opcode.PIX_ON);
            },

            // Game
            Opcode.WAIT => {
                const ms = try read2B(rom_file, io, &file_pos);
                sc.waitMs(ms);
            },
            Opcode.RECV => {},
            Opcode.END => break,
            else => {},
        }
    }
}
