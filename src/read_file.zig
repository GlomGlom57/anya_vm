const std = @import("std");

pub const mem_len = 128;
pub const mem_margin = 5;
const start_size = @sizeOf(u32);

pub fn fill_mem(rom_file: *std.Io.File, io: std.Io, mem_buffer: *[mem_len]u8, last_dir: *u32) !void {
    // Verify if the mem leen exceeds the pos + rom_file size + start size bytes
    const file_lenght = try rom_file.length(io);
    if (file_lenght - start_size < last_dir.* + mem_len) last_dir.* = @as(u32, @intCast(file_lenght)) - mem_len - start_size;

    _ = try rom_file.readPositionalAll(io, mem_buffer, last_dir.*);
}

pub fn read2B(mem_buffer: *[mem_len]u8, pos: *u32, last_dir: *u32) !u16 {
    const buff: [2]u8 = .{ mem_buffer[pos.* - last_dir.*], mem_buffer[pos.* + 1 - last_dir.*] };
    pos.* += 2;
    return std.mem.readInt(u16, &buff, .big);
}

pub fn read1B(mem_buffer: *[mem_len]u8, pos: *u32, last_dir: *u32) !u8 {
    const buff: [1]u8 = .{mem_buffer[pos.* - last_dir.*]};
    pos.* += 1;
    return std.mem.readInt(u8, &buff, .big);
}
