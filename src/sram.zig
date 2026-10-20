const std = @import("std");

const exec = @import("executor.zig");
const rf = @import("read_file.zig");
const alu = @import("alu.zig");

pub const sram_size = 255;

pub fn load_data(opcode: exec.Opcode, mem_buffer: *[rf.mem_len]u8, file_pos: *u32, last_dir: u32, sram: *[sram_size]u8, frame: u8, acumulator: *u16, acumulator_type: *alu.DType) void {
    if (opcode == exec.Opcode.LOAD_U8 or opcode == exec.Opcode.LOAD_I8) {
        const dir = try rf.read1b_buffer(mem_buffer, file_pos, last_dir); // Get local dir
        const value = sram[frame + dir]; // Get value
        acumulator.* = value;
        acumulator_type.* = if (opcode == exec.Opcode.LOAD_U8) alu.DType.U8 else alu.DType.I8;
        return;
    }
    const dir = try rf.read2b_buffer(mem_buffer, file_pos, last_dir); // Get local dir
    const mem: [2]u8 = .{ sram[frame + dir], sram[frame + dir + 1] };
    const value: u16 = std.mem.readInt(u16, &mem, .big); // Get value from 2 bytes
    acumulator.* = value;
    acumulator_type.* = if (opcode == exec.Opcode.LOAD_U16) alu.DType.U16 else alu.DType.I16;
}

pub fn reserve_space(sram_pointer: *u8, bytes: u8) void {
    sram_pointer += bytes;
}
