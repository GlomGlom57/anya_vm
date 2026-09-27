const std = @import("std");
const sc = @import("screen.zig");

pub const data_size = @sizeOf(u16);
pub const ddata_size = 50;
const sram_size = 20;

const DType = enum(u8) {
    U8 = 0x00,
    I8 = 0x01,
    U16 = 0x02,
    I16 = 0x03,
};

const Opcode = enum(u8) {
    // Memory
    LOAD_C = 0x00,
    LOAD_I8 = 0x01,
    LOAD_U8 = 0x02,
    LOAD_I16 = 0x03,
    LOAD_U16 = 0x04,
    STORE = 0x05,

    // Math
    ADD = 0x06,
    SUB = 0x07,
    MPL = 0x08,
    DIV = 0x09,

    // Jumps
    JMP = 0x0A,
    JMP_P = 0x0B,
    JMP_N = 0x0C,
    JMP_Z = 0x0D,
    JMP_NZ = 0x0E,

    // Functions
    CALL = 0x0F,
    RET = 0x10,

    // Screen
    CLEAR = 0x11,
    SHOW = 0x12,
    PIX_ON = 0x13,
    PIX_OFF = 0x14,

    // Game
    WAIT = 0x15, // Wait ms
    RECV = 0x16, // Read keyboard
    END = 0x17, // End game

    // Keyboard
    //  Movement
    LFT = 0x18,
    RGT = 0x19,
    UP = 0x1A,
    DWN = 0x1B,

    //  Actions
    BTA = 0x1C,
    BTB = 0x1D,
    BTC = 0x1E,
    BTD = 0x1F,
    SPC = 0x20,

    // Data
    V_U8 = 0x21,
    V_I8 = 0x22,
    V_U16 = 0x23,
    V_I16 = 0x24,
};

pub fn read2B(rom_file: *std.Io.File, io: std.Io, pos: *u64) !u16 {
    var buff: [2]u8 = undefined;

    _ = try rom_file.readPositionalAll(
        io,
        &buff,
        pos.*,
    );

    pos.* += 2;
    return std.mem.readInt(u16, &buff, .big);
}

pub fn read1B(rom_file: *std.Io.File, io: std.Io, pos: *u64) !u8 {
    var buff: [1]u8 = undefined;

    _ = try rom_file.readPositionalAll(
        io,
        &buff,
        pos.*,
    );

    pos.* += 1;
    return std.mem.readInt(u8, &buff, .big);
}

pub fn exec_game(rom_file: *std.Io.File, io: std.Io, file_size: u64, start_addr: u64) !void {
    var file_pos: u64 = start_addr;

    // Generate screen
    var screenBuffer: [sc.screenWidth][sc.screenHeight]bool = undefined;
    sc.clearScreen(&screenBuffer);

    // Registers
    var acumulator: u16 = 0;
    var acumulator_type: DType = undefined;

    // Ram
    var sram: [sram_size]u8 = undefined;
    var sram_pointer: u8 = 0;

    // Read instructions
    while (file_pos <= file_size - 1 - data_size * 2) {
        const word = try read1B(rom_file, io, &file_pos);
        const opcode: Opcode = @enumFromInt(word);
        std.log.debug("Opcode: 0x{X:0>2}", .{opcode});

        switch (opcode) {
            // Memory
            Opcode.LOAD_C => {
                // Get const type
                const typeB = try read1B(rom_file, io, &file_pos);
                acumulator_type = @enumFromInt(typeB);

                // Get value
                acumulator = if (typeB < 2)
                    try read1B(rom_file, io, &file_pos) // Read U8 or I8
                else
                    try read2B(rom_file, io, &file_pos); // Read U16 or I16
            },
            Opcode.LOAD_U8, Opcode.LOAD_I8 => {
                const dir = try read1B(rom_file, io, &file_pos); // Get local dir
                const value = sram[sram_pointer + dir]; // Get value
                acumulator = value;
                acumulator_type = if (opcode == Opcode.LOAD_U8) DType.U8 else DType.I8;
            },
            Opcode.LOAD_U16, Opcode.LOAD_I16 => {
                const dir = try read2B(rom_file, io, &file_pos); // Get local dir
                const value: u16 = std.mem.readInt(u16, sram[sram_pointer + dir], .big); // Get value from 2 bytes
                acumulator = value;
                acumulator_type = if (opcode == Opcode.LOAD_U16) DType.U16 else DType.I16;
            },
            Opcode.STORE => {
                const dir = try read1B(rom_file, io, &file_pos);
                if (acumulator_type == DType.U8 or acumulator_type == DType.I8) sram[sram_pointer + dir] = acumulator; // Save 1 byte
            },

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
                var posx = try read1B(rom_file, io, &file_pos);
                var posy = try read1B(rom_file, io, &file_pos);

                if (posx < sc.screenWidth) // Verify if the X coord is fixed
                    std.log.info("Fixed X: {d}", .{posx})
                else { // If not, it means is trying to draw pixel from sram
                    posx = sram[posx - sc.screenWidth];
                    std.log.info("Variable X: {d}", .{posx});
                }

                if (posy < sc.screenHeight) // Verify if the Y coord is fixed
                    std.log.info("Fixed Y: {d}", .{posy})
                else { // If not, it means is trying to draw pixel from sram
                    posy = sram[posy - sc.screenHeight];
                    std.log.info("Variable Y: {d}", .{posy});
                }
                sc.setPixel(&screenBuffer, posx, posy, opcode == Opcode.PIX_ON);
            },

            // Game
            Opcode.WAIT => {
                const ms = try read2B(rom_file, io, &file_pos);
                sc.waitMs(ms);
            },
            Opcode.RECV => {},
            Opcode.END => break,
            else => {
                std.log.err("Invalid opcode: {d}", .{word});
                break;
            },

            // Data: Reserve space, move sram_pointer
            Opcode.V_U8, Opcode.V_I8 => sram_pointer += 1,
            Opcode.V_U16, Opcode.V_I16 => sram_pointer += 2,
        }
    }
}
