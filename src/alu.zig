const std = @import("std");

const rf = @import("read_file.zig");
const exec = @import("executor.zig");
const sr = @import("sram.zig");

//  For verify if signed int is positive or negative
const i8_middle = 128;
const i16_middle = 32768;

pub const DType = enum(u8) {
    U8 = 0x00,
    I8 = 0x01,
    U16 = 0x02,
    I16 = 0x03,
};

// In case of const + var, must load the const first,
// so dont need something like ADD_C, SUB_C, etc.
// In case of const1 + const2 + var or other, just create
// the result of const1 + const2 in a const3, and make
// const3 + var directly.
pub fn calc(opcode: exec.Opcode, mem_buffer: *[rf.mem_len]u8, file_pos: *u32, last_dir: u32, sram: *[sr.sram_size]u8, frame: u8, acumulator: *u16, acumulator_type: *DType, const_loaded: *bool) void {
    const dir = try rf.read1b_buffer(mem_buffer, file_pos, last_dir);
    var value: u16 = undefined;
    if (acumulator_type.* == DType.U8 or acumulator_type.* == DType.I8) {
        value = @intCast(sram[frame + dir]);
    } else {
        const content: [2]u8 = .{ sram[frame + dir], sram[frame + dir + 1] };
        value = std.mem.readInt(u16, &content, .big);
    }

    acumulator.* = switch (opcode) {
        exec.Opcode.ADD => acumulator.* +% value,
        exec.Opcode.MPL => acumulator.* *% value,
        exec.Opcode.SUB => if (const_loaded.*) value -% acumulator.* else acumulator.* -% value,
        else => if (const_loaded.*) value / acumulator.* else acumulator.* / value,
    };

    if (const_loaded.*) const_loaded.* = false;
}

pub fn jmp(
    opcode: exec.Opcode,
    mem_buffer: *[rf.mem_len]u8,
    file_pos: *u32,
    last_dir: u32,
    acumulator: u16,
    acumulator_type: DType,
) bool {
    const dir = try rf.read4b_buffer(mem_buffer, file_pos, last_dir);
    const middle: u16 = if (acumulator_type == DType.I8) i8_middle else i16_middle;

    if (opcode == exec.Opcode.JMP_P or opcode == exec.Opcode.JMP_N) {
        if (acumulator_type == DType.U8 or acumulator_type == DType.U16) { // The DType es U8 or I16 (always positive)
            if (opcode == exec.Opcode.JMP_P) file_pos.* = dir; // If the operation es JMP_P
            return true;
        }

        if ((opcode == exec.Opcode.JMP_P and acumulator <= middle) or (opcode == exec.Opcode.JMP_N and acumulator > middle)) file_pos.* = dir;
    } else { // JMP_Z or JMP_NZ
        if (acumulator_type == DType.U8 or acumulator_type == DType.U16) {
            if ((opcode == exec.Opcode.JMP_Z and acumulator == 0) or (opcode == exec.Opcode.JMP_NZ and acumulator != 0)) file_pos.* = dir;
            return true;
        }

        if ((opcode == exec.Opcode.JMP_Z and acumulator == middle) or (opcode == exec.Opcode.JMP_NZ and acumulator != middle)) file_pos.* = dir;
    }

    return false;
}
