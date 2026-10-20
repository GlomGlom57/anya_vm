const std = @import("std");

pub const mem_len = 128;
pub const mem_margin = 5;
pub const start_type = u32;
pub const start_size = @sizeOf(start_type);

pub fn fill_mem(rom_file: *std.Io.File, io: std.Io, mem_buffer: *[mem_len]u8, last_dir: *u32) !void {
    // Verify if the mem leen exceeds the pos + rom_file size + start size bytes
    const file_lenght = try rom_file.length(io);
    if (file_lenght - start_size < last_dir.* + mem_len) last_dir.* = @as(u32, @intCast(file_lenght)) - mem_len - start_size;

    _ = try rom_file.readPositionalAll(io, mem_buffer, last_dir.*);
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

pub fn read4b_buffer(mem_buffer: *[mem_len]u8, pos: *u32, last_dir: u32) !u32 {
    var buff: [4]u8 = undefined;
    for (0..4) |i| buff[i] = mem_buffer[pos.* + i - last_dir];
    pos.* += 4;
    return std.mem.readInt(u32, &buff, .big);
}

pub fn read2b_buffer(mem_buffer: *[mem_len]u8, pos: *u32, last_dir: u32) !u16 {
    const buff: [2]u8 = .{ mem_buffer[pos.* - last_dir], mem_buffer[pos.* + 1 - last_dir] };
    pos.* += 2;
    return std.mem.readInt(u16, &buff, .big);
}

pub fn read1b_buffer(mem_buffer: *[mem_len]u8, pos: *u32, last_dir: u32) !u8 {
    const buff: [1]u8 = .{mem_buffer[pos.* - last_dir]};
    pos.* += 1;
    return std.mem.readInt(u8, &buff, .big);
}
