const rl = @import("raylib");
const std = @import("std");

const size_aumented = 10;
pub const buffWidth = 128;
pub const buffHeight = 64;
pub const screenWidth = buffWidth * size_aumented;
pub const screenHeight = buffHeight * size_aumented;
pub const data_section_size = 20;
pub const fps = 60;

pub fn clearScreen(buffer: *[buffWidth][buffHeight]bool, is_white: bool) void {
    for (0..buffWidth) |x| {
        for (0..buffHeight) |y|
            buffer[x][y] = is_white;
    }
}

pub fn show_info(
    file_pos: u32,
    first_pos: u32,
    last_dir: u32,
    frame: u32,
    sram_pointer: u32,
    acumulator: u16,
    gpa: std.mem.Allocator,
) void {
    rl.drawRectangle(0, screenHeight, screenWidth, data_section_size, .blue);
    const format: [:0]const u8 = std.fmt.allocPrintSentinel(gpa, "File pos: {d}| First pos: {d}| Last dir: {d}| Frame: {d}| SRAM pointer: {d}| Acumulator: {d}", .{ file_pos, first_pos, last_dir, frame, sram_pointer, acumulator }, 0) catch |err| {
        std.log.err("Cant reserve format memory: {}", .{err});
        std.process.exit(1);
    };
    rl.drawText(format, 0, screenHeight, data_section_size, .white);
    gpa.free(format);
}

pub fn showScreen(buffer: [buffWidth][buffHeight]bool) void {
    for (0..buffWidth) |x| {
        for (0..buffHeight) |y| {
            const color = if (buffer[x][y]) rl.Color.white else rl.Color.black;
            rl.drawRectangle(@intCast(x * size_aumented), @intCast(y * size_aumented), size_aumented, size_aumented, color);
        }
    }
}

pub fn setPixel(buffer: *[buffWidth][buffHeight]bool, x: u8, y: u8, enabled: bool) void {
    buffer[x][y] = enabled;
}

pub fn waitMs(ms: u16) void {
    const msCast: f64 = @floatFromInt(ms);
    rl.waitTime(msCast / 1000);
}
