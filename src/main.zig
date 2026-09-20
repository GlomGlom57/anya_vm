const std = @import("std");
const rl = @import("raylib");
const sc = @import("screen.zig");
const exe = @import("executor.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const args = try init.minimal.args.toSlice(gpa);

    if (args.len != 2) {
        std.log.err("Error: You must only pass the ROM file.", .{});
        std.process.exit(1);
    }

    rl.initWindow(sc.screenWidth, sc.screenHeight, "Anya Runtime");
    defer rl.closeWindow();

    rl.setTargetFPS(sc.fps);
    var screenBuffer: [sc.screenHeight][sc.screenWidth]bool = undefined;

    // Clear screen
    sc.clearScreen(&screenBuffer);
    sc.showScreen(&screenBuffer);

    try exe.exec_game();
}
