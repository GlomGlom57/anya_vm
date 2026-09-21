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

    try exe.gen_vars(&rom_file, io, file_size); // Gen vars

    // Start screen
    rl.setTraceLogLevel(rl.TraceLogLevel.err);
    rl.initWindow(sc.screenWidth, sc.screenHeight, "Anya Runtime");
    defer rl.closeWindow();

    rl.setTargetFPS(sc.fps);
    var screenBuffer: [sc.screenHeight][sc.screenWidth]bool = undefined;

    // Clear screen
    sc.clearScreen(&screenBuffer);
    sc.showScreen(&screenBuffer);

    try exe.exec_game(&rom_file, io, file_size); // Start game
}
