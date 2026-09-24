const std = @import("std");
const rl = @import("raylib");
const sc = @import("screen.zig");
const exe = @import("executor.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;
    const args = try init.minimal.args.toSlice(gpa);

    // Get ROM file path
    if (args.len != 2) {
        std.log.err("Error: You must only pass the ROM file.", .{});
        std.process.exit(1);
    }

    // Open ROM file
    const rom_path = args[1];
    gpa.free(args);

    var rom_file = std.Io.Dir.cwd().openFile(io, rom_path, .{ .mode = .read_only }) catch {
        std.log.err("Error: Could not open ROM file.", .{});
        std.process.exit(2);
    };
    defer rom_file.close(io);

    const file_size = try rom_file.length(io);

    var buff: [2]u8 = undefined;

    _ = try rom_file.readPositionalAll(
        io,
        &buff,
        file_size - exe.data_size,
    );
    const start_addr = std.mem.readInt(u16, &buff, .little);
    std.log.info("Start addr: {d}", .{start_addr});

    // Start screen
    rl.setTraceLogLevel(rl.TraceLogLevel.err);
    rl.initWindow(sc.screenWidth, sc.screenHeight, "Anya Runtime");
    defer rl.closeWindow();

    rl.setTargetFPS(sc.fps);

    try exe.exec_game(&rom_file, io, file_size, start_addr); // Start game
}
