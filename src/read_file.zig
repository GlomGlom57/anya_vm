const std = @import("std");

pub const mem_len = 255;
pub const mem_margin = 5;
pub const start_type = u32;
pub const start_size = @sizeOf(start_type);

pub fn fill_mem(rom_file: *std.Io.File, io: std.Io, mem_buffer: *[mem_len]u8, first_dir: *u32, last_dir: *u32, file_size: u64) !void {
    // Verify if the mem leen exceeds the pos + rom_file size + start size bytes
    first_dir.* = last_dir.*;
    if (file_size > mem_len) {
        if ((file_size - start_size < last_dir.* + mem_len)) {
            last_dir.* = @intCast(file_size - start_size);
            std.log.debug("Last dir updated: {d}", .{last_dir.*});
        }
    }

    _ = try rom_file.readPositionalAll(io, mem_buffer, first_dir.*);
}

pub fn read2b_file(rom_file: *std.Io.File, io: std.Io, pos: *u32) !u16 {
    var buff: [2]u8 = undefined;

    _ = try rom_file.readPositionalAll(io, &buff, pos.*);
    pos.* += 2;

    return std.mem.readInt(u16, &buff, .big);
}

pub fn read1b_file(rom_file: *std.Io.File, io: std.Io, pos: *u32) !u8 {
    var buff: [1]u8 = undefined;

    _ = try rom_file.readPositionalAll(io, &buff, pos.*);
    pos.* += 1;

    return std.mem.readInt(u8, &buff, .big);
}

pub fn read4b_buffer(mem_buffer: *[mem_len]u8, pos: *u32, first_dir: u32) !u32 {
    var buff: [4]u8 = undefined;
    for (0..4) |i| buff[i] = mem_buffer[pos.* + i - first_dir];
    pos.* += 4;
    return std.mem.readInt(u32, &buff, .big);
}

pub fn read2b_buffer(mem_buffer: *[mem_len]u8, pos: *u32, first_dir: u32) !u16 {
    const buff: [2]u8 = .{ mem_buffer[pos.* - first_dir], mem_buffer[pos.* + 1 - first_dir] };
    pos.* += 2;
    return std.mem.readInt(u16, &buff, .big);
}

pub fn read1b_buffer(mem_buffer: *[mem_len]u8, pos: *u32, first_dir: u32) !u8 {
    std.log.debug("Loading dir {d}", .{pos.*});
    std.log.debug("Calc dir {d} - {d}", .{ pos.*, first_dir });
    const buff: [1]u8 = .{mem_buffer[pos.* - first_dir]};
    pos.* += 1;
    return std.mem.readInt(u8, &buff, .big);
}
