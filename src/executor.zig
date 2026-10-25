const std = @import("std");

const sc = @import("screen.zig");
const rf = @import("read_file.zig");
const kb = @import("buttons.zig");
const sr = @import("sram.zig");
const alu = @import("alu.zig");
const rl = @import("raylib");

pub const Opcode = enum(u8) {
    // Memory
    LOAD_C = 0x00,

    LOAD_I8 = 0x01,
    LOAD_U8 = 0x02,
    LOAD_I16 = 0x03,
    LOAD_U16 = 0x04,

    LOAD_VAR_DIR = 0x05,

    STORE = 0x06,
    STORE_VAR_DIR = 0x07,
    STORE_TO_DIR = 0x08,

    // Math
    ADD = 0x09,
    SUB = 0x0A,
    MPL = 0x0B,
    DIV = 0x0C,

    // Jumps
    JMP = 0x0D,
    JMP_P = 0x0E,
    JMP_N = 0x0F,
    JMP_Z = 0x10,
    JMP_NZ = 0x11,

    // Functions
    CALL = 0x12,
    RET = 0x13,

    // Screen
    CLEAR_W = 0x14,
    CLEAR_B = 0x15,
    SHOW = 0x16,
    PIX_ON = 0x17,
    PIX_OFF = 0x18,

    // Game
    WAIT = 0x19, // Wait ms
    RECV = 0x1A, // Read keyboard
    CLEARBT = 0x1B, // Clear keyboar state
    END = 0x1C, // End game

    // Keyboard
    // What preceeds buttons is the JUMP dir
    BTR1C1 = 0x1D,
    BTR1C2 = 0x1E,
    BTR1C3 = 0x1F,
    BTR1C4 = 0x20,

    BTR2C1 = 0x21,
    BTR2C2 = 0x22,
    BTR2C3 = 0x23,
    BTR2C4 = 0x24,

    BTR3C1 = 0x25,
    BTR3C2 = 0x26,
    BTR3C3 = 0x27,
    BTR3C4 = 0x28,

    BTR4C1 = 0x29,
    BTR4C2 = 0x2A,
    BTR4C3 = 0x2B,
    BTR4C4 = 0x2C,

    // SRAM pointer
    SRAMP_ADD = 0x2D,
    SRAMP_SUB = 0x2E,

    // OTHER ADDS
    PIX_ON_M = 0x2F,
    PIX_OFF_M = 0x30,

    PRIORITY_ON = 0x31,
    PRIORITY_OFF = 0x32,
};

pub fn exec_game(rom_file: *std.Io.File, io: std.Io, file_size: u64, start_addr: u32, gpa: std.mem.Allocator) !void {
    var file_pos: u32 = start_addr;

    // SD Memory
    var mem_buffer: [rf.mem_len]u8 = undefined;
    var first_dir: u32 = file_pos;
    var last_dir: u32 = file_pos;

    try rf.fill_mem(rom_file, io, &mem_buffer, &first_dir, &last_dir, file_size); // Fill the buffer the first time
    for (0..rf.mem_len) |i| std.log.info("Dir {d}: 0x{X:0>2}", .{ i, mem_buffer[i] });

    // Generate screen
    var screenBuffer: [sc.buffWidth][sc.buffHeight]bool = undefined;
    sc.clearScreen(&screenBuffer, false);

    // Registers
    var acumulator: u16 = 0;
    var acumulator_type: alu.DType = undefined;

    // SRAM
    var sram: [sr.sram_size]u8 = undefined;
    var sram_pointer: u8 = 0;
    var frame: u8 = 0;

    var priority: bool = false; // For SUB or DIV, where const comes first
    var btns: u16 = 0;

    // Read instructions
    while (!rl.windowShouldClose() and file_pos < file_size - rf.start_size) {
        // Refill mem buffer if its necessary
        if (file_pos >= last_dir + rf.mem_len - rf.mem_margin) {
            try rf.fill_mem(rom_file, io, &mem_buffer, &first_dir, &last_dir, file_size);
            std.log.debug("Memory refilled.", .{});
        }

        std.log.debug("First dir: {d}", .{first_dir});
        std.log.debug("File pos: {d}", .{file_pos});
        std.log.debug("Last dir: {d}", .{last_dir});
        std.log.debug("Acum: {d}", .{acumulator});

        const word = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
        std.log.debug("Word: 0x{X:0>2}", .{word});

        const opcode: Opcode = @fromBackingInt(@intCast(word));

        switch (opcode) {
            // Memory
            Opcode.LOAD_C => {
                // Get const dir
                var dir: u32 = try rf.read4b_buffer(&mem_buffer, &file_pos, first_dir);

                // Get const type
                const typeB = try rf.read1b_file(rom_file, io, &dir);
                std.log.debug("Trying to cast {d} from dir {d}", .{ typeB, dir });
                acumulator_type = @fromBackingInt(@intCast(typeB));

                // Get value
                if (typeB < 2) acumulator = try rf.read1b_file(rom_file, io, &dir) // Read U8 or I8
                else acumulator = try rf.read2b_file(rom_file, io, &dir); // Read U16 or I16

                std.log.debug("Loading const from {d}: {d}", .{ dir, acumulator });
            },

            Opcode.LOAD_U8, Opcode.LOAD_I8, Opcode.LOAD_U16, Opcode.LOAD_I16 => sr.load_data(opcode, &mem_buffer, &file_pos, last_dir, &sram, frame, &acumulator, &acumulator_type),

            Opcode.LOAD_VAR_DIR => {
                // Get var ptr
                var ptr: u32 = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
                // Get data type : LOAD_C empty consts only for setting data type
                // Get data value
                acumulator = if (acumulator_type == alu.DType.U8 or acumulator_type == alu.DType.I8) try rf.read1b_buffer(&mem_buffer, &ptr, last_dir) else try rf.read2b_buffer(&mem_buffer, &ptr, last_dir);
            },

            Opcode.STORE => {
                const dir = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
                var buff: [2]u8 = undefined;
                std.mem.writeInt(u16, &buff, acumulator, .big);
                if (acumulator_type == alu.DType.U8 or acumulator_type == alu.DType.I8) {
                    sram[frame + dir] = buff[1]; // Save 1 byte
                } else {
                    sram[frame + dir] = buff[0];
                    sram[frame + dir + 1] = buff[1]; // Save 2 bytes
                }
            },
            Opcode.STORE_VAR_DIR => {
                // Get var dir
                const dir = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
                // Save var dir on acum
                acumulator_type = alu.DType.U8;
                acumulator = sram[frame + dir];
                // Then save the acum value on U8
            },
            Opcode.STORE_TO_DIR => {
                // Get var pointer
                const ptr = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
                // Get var type : LOAD_C empty consts only for setting data type
                // Save acum to ptr
                if (acumulator_type == alu.DType.U8 or acumulator_type == alu.DType.I8) sram[frame + ptr] = @intCast(acumulator) else {
                    var buff: [2]u8 = undefined;
                    std.mem.writeInt(u16, &buff, acumulator, .big);
                    sram[frame + ptr] = buff[0];
                    sram[frame + ptr + 1] = buff[1];
                }
            },

            // Math
            Opcode.ADD, Opcode.SUB, Opcode.MPL, Opcode.DIV => alu.calc(opcode, &mem_buffer, &file_pos, last_dir, &sram, frame, &acumulator, &acumulator_type, priority),

            // Jumps
            Opcode.JMP => {
                const dir = try rf.read4b_buffer(&mem_buffer, &file_pos, first_dir);
                std.log.debug("--------Jumping incond to: {d}--------", .{dir});
                file_pos = dir;
            },
            Opcode.JMP_P, Opcode.JMP_N, Opcode.JMP_NZ, Opcode.JMP_Z => if (alu.jmp(opcode, &mem_buffer, &file_pos, first_dir, acumulator, acumulator_type)) {
                std.log.debug("--------Jumping cond to: {d}--------", .{file_pos});
                continue;
            },

            // Functions
            Opcode.CALL => { // Save the current dir an change the dir that the call asks
                // Save current function frame
                sram[sram_pointer] = frame;
                sram_pointer += 1;

                // Save current file pos
                var buff: [4]u8 = undefined;
                std.mem.writeInt(u32, &buff, file_pos, .big);
                for (0..4) |i| {
                    sram[sram_pointer + i] = buff[i];
                    sram_pointer += 1;
                }

                // Go to dir
                file_pos = try rf.read4b_buffer(&mem_buffer, &file_pos, first_dir);
            },
            Opcode.RET => {
                // Clean sram pointer
                const bytes = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
                sram_pointer -= bytes;

                // Load last file pos
                var buff: [4]u8 = undefined;
                for (0..4) |i| {
                    buff[i] = sram[frame - i];
                    sram_pointer -= 1;
                }
                file_pos = std.mem.readInt(u32, &buff, .little);

                // Get last frame
                sram_pointer -= 1;
                frame = sram[sram_pointer];
            },

            // Screen
            Opcode.CLEAR_W, Opcode.CLEAR_B => sc.clearScreen(&screenBuffer, opcode == Opcode.CLEAR_W),
            Opcode.SHOW => {
                rl.beginDrawing();
                sc.showScreen(screenBuffer);
                sc.show_info(file_pos, first_dir, last_dir, frame, sram_pointer, acumulator, gpa);
                rl.endDrawing();
            },

            Opcode.PIX_ON, Opcode.PIX_OFF => {
                const posx = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
                const posy = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);

                std.log.debug("Fixed X: {d}", .{posx});
                std.log.debug("Fixed Y: {d}", .{posy});
                sc.setPixel(&screenBuffer, posx, posy, opcode == Opcode.PIX_ON);
            },

            Opcode.PIX_ON_M, Opcode.PIX_OFF_M => {
                const posx_dir = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);
                const posy_dir = try rf.read1b_buffer(&mem_buffer, &file_pos, first_dir);

                const posx = sram[frame + posx_dir];
                const posy = sram[frame + posy_dir];

                std.log.debug("Mem X: {d}", .{posx});
                std.log.debug("Mem Y: {d}", .{posy});
                sc.setPixel(&screenBuffer, posx, posy, opcode == Opcode.PIX_ON_M);
            },

            // Game
            Opcode.WAIT => {
                const ms = try rf.read2b_buffer(&mem_buffer, &file_pos, last_dir);
                sc.waitMs(ms);
            },
            Opcode.RECV => {
                const ms = try rf.read2b_buffer(&mem_buffer, &file_pos, last_dir);
                kb.read_buttons(&btns, ms);
            },
            Opcode.CLEARBT => kb.clear_pressed(&btns),
            Opcode.END => break,

            // Data: Reserve space, move sram_pointer
            Opcode.SRAMP_ADD, Opcode.SRAMP_SUB => {
                const n = try rf.read1b_buffer(&mem_buffer, &file_pos, last_dir);
                if (opcode == Opcode.SRAMP_ADD) sram_pointer += n else sram_pointer -= n;
            },

            Opcode.PRIORITY_ON => priority = true,
            Opcode.PRIORITY_OFF => priority = false,

            // Buttons or err
            else => {
                if (word > @backingInt(Opcode.END) and word < @backingInt(Opcode.SRAMP_ADD)) {
                    const dir = try rf.read4b_buffer(&mem_buffer, &file_pos, last_dir);
                    if (kb.is_pressed(btns, @intCast(word - @backingInt(Opcode.BTR1C1)))) file_pos = dir;
                    continue;
                }

                // If not, is an invalid opcode
                std.log.err("Invalid opcode: {d}", .{word});
                std.log.debug("ALU:", .{});
                std.log.debug("  Acumulator: {d}", .{acumulator});
                std.log.debug("  Acumulator type: {}", .{acumulator_type});
                std.log.debug("SRAM:", .{});
                std.log.debug("  Frame: {d}", .{frame});
                std.log.debug("  SRAM pointer: {d}", .{sram_pointer});
                std.log.debug("Program:", .{});
                std.log.debug("  File position: {d}", .{file_pos});
                std.log.debug("  Last position: {d}", .{last_dir});
                break;
            },
        }
    }
}
