const std = @import("std");
const sc = @import("screen.zig");

pub const data_size = @sizeOf(u16);
pub const ddata_size = 50;
const sram_size = 20;
const u8_middle = 128;
const u16_middle = 32768;

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
    CLEAR_W = 0x11,
    CLEAR_B = 0x12,
    SHOW = 0x13,
    PIX_ON = 0x14,
    PIX_OFF = 0x15,

    // Game
    WAIT = 0x16, // Wait ms
    RECV = 0x17, // Read keyboard
    END = 0x18, // End game

    // Keyboard
    //  Movement
    LFT = 0x19,
    RGT = 0x1A,
    UP = 0x1B,
    DWN = 0x1C,

    //  Actions
    BTA = 0x1D,
    BTB = 0x1E,
    BTC = 0x1F,
    BTD = 0x20,
    SPC = 0x21,

    // Data
    V_U8 = 0x22,
    V_I8 = 0x23,
    V_U16 = 0x24,
    V_I16 = 0x25,
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
    sc.clearScreen(&screenBuffer, false);

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
                // Get const dir
                var dir: u64 = try read2B(rom_file, io, &file_pos);

                // Get const type
                const typeB = try read1B(rom_file, io, &dir);
                acumulator_type = @enumFromInt(typeB);

                // Get value
                acumulator = if (typeB < 2)
                    try read1B(rom_file, io, &dir) // Read U8 or I8
                else
                    try read2B(rom_file, io, &dir); // Read U16 or I16
            },
            Opcode.LOAD_U8, Opcode.LOAD_I8 => {
                const dir = try read1B(rom_file, io, &file_pos); // Get local dir
                const value = sram[sram_pointer + dir]; // Get value
                acumulator = value;
                acumulator_type = if (opcode == Opcode.LOAD_U8) DType.U8 else DType.I8;
            },
            Opcode.LOAD_U16, Opcode.LOAD_I16 => {
                const dir = try read2B(rom_file, io, &file_pos); // Get local dir
                const mem: [2]u8 = .{ sram[sram_pointer + dir], sram[sram_pointer + dir + 1] };
                const value: u16 = std.mem.readInt(u16, &mem, .big); // Get value from 2 bytes
                acumulator = value;
                acumulator_type = if (opcode == Opcode.LOAD_U16) DType.U16 else DType.I16;
            },
            Opcode.STORE => {
                const dir = try read1B(rom_file, io, &file_pos);
                if (acumulator_type == DType.U8 or acumulator_type == DType.I8) {
                    sram[sram_pointer + dir] = @intCast(acumulator);
                } // Save 1 byte
                else {
                    var buff: [2]u8 = undefined;
                    std.mem.writeInt(u16, &buff, acumulator, .big);
                    sram[sram_pointer + dir] = buff[0];
                    sram[sram_pointer + dir + 1] = buff[1];
                } // Save 2 bytes
            },

            // Math
            // In case of const + var, must load the const first,
            // so dont need something like ADD_C, SUB_C, etc.
            // In case of const1 + const2 + var or other, just create
            // the result of const1 + const2 in a const3, and make
            // const3 + var directly.
            Opcode.ADD, Opcode.SUB, Opcode.MPL, Opcode.DIV => {
                const dir = try read1B(rom_file, io, &file_pos);
                var value: u16 = undefined;
                if (acumulator_type == DType.U8 or acumulator_type == DType.I8) {
                    value = @intCast(sram[sram_pointer + dir]);
                } else {
                    const content: [2]u8 = .{ sram[sram_pointer + dir], sram[sram_pointer + dir + 1] };
                    value = std.mem.readInt(u16, &content, .big);
                }

                acumulator = switch (opcode) {
                    Opcode.ADD => acumulator +% value,
                    Opcode.SUB => acumulator -% value,
                    Opcode.MPL => acumulator *% value,
                    else => acumulator / value,
                };
            },

            // Jumps
            Opcode.JMP => {
                const dir = try read2B(rom_file, io, &file_pos);
                file_pos = dir;
            },
            Opcode.JMP_P, Opcode.JMP_N => {
                const dir = try read2B(rom_file, io, &file_pos);
                if (acumulator_type == DType.U8 or acumulator_type == DType.U16) { // The DType es U8 or I16 (always positive)
                    if (opcode == Opcode.JMP_P) file_pos = dir; // If the operation es JMP_P
                    continue;
                }

                const middle: u16 = if (acumulator_type == DType.I8) u8_middle else u16_middle;
                if ((opcode == Opcode.JMP_P and acumulator <= middle) or (opcode == Opcode.JMP_N and acumulator > middle)) file_pos = dir;
            },
            Opcode.JMP_Z, Opcode.JMP_NZ => {
                const dir = try read2B(rom_file, io, &file_pos);
                if (acumulator_type == DType.U8 or acumulator_type == DType.U16) {
                    if ((opcode == Opcode.JMP_Z and acumulator == 0) or (opcode == Opcode.JMP_NZ and acumulator != 0)) file_pos = dir;
                    continue;
                }

                const middle: u16 = if (acumulator_type == DType.I8) u8_middle else u16_middle;
                if ((opcode == Opcode.JMP_Z and acumulator == middle) or (opcode == Opcode.JMP_NZ and acumulator != middle)) file_pos = dir;
            },

            Opcode.CALL => {}, // Save the current dir an change the dir that the call asks
            Opcode.RET => {}, // Return the memory dir where is the number of bytes to free from sram_pointer

            // Screen
            Opcode.CLEAR_W => sc.clearScreen(&screenBuffer, true),
            Opcode.CLEAR_B => sc.clearScreen(&screenBuffer, false),
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
