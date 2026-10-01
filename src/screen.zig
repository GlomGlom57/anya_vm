const rl = @import("raylib");

pub const screenWidth = 128;
pub const screenHeight = 64;
pub const fps = 60;

pub fn clearScreen(buffer: *[screenWidth][screenHeight]bool, is_white: bool) void {
    for (0..screenHeight) |y| {
        for (0..screenWidth) |x|
            buffer[x][y] = is_white;
    }
}

pub fn showScreen(buffer: *[screenWidth][screenHeight]bool) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    for (0..screenHeight) |y| {
        for (0..screenWidth) |x| {
            const color = if (buffer[x][y]) rl.Color.white else rl.Color.black;
            rl.drawPixel(@intCast(x), @intCast(y), color);
        }
    }
}

pub fn setPixel(buffer: *[screenWidth][screenHeight]bool, x: u8, y: u8, enabled: bool) void {
    buffer[x][y] = enabled;
}

pub fn waitMs(ms: u16) void {
    const msCast: f64 = @floatFromInt(ms);
    rl.waitTime(msCast / 1000);
}
