const rl = @import("raylib");

pub const screenWidth = 128;
pub const screenHeight = 64;
pub const fps = 60;

pub fn clearScreen(buffer: *[screenHeight][screenWidth]bool) void {
    for (0..screenHeight) |y| {
        for (0..screenWidth) |x|
            buffer[y][x] = false;
    }
}

pub fn showScreen(buffer: *[screenHeight][screenWidth]bool) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    for (0..screenHeight) |y| {
        for (0..screenWidth) |x| {
            const color = if (buffer[y][x]) rl.Color.white else rl.Color.black;
            rl.drawPixel(@intCast(x), @intCast(y), color);
        }
    }
}

pub fn setPixel(buffer: *[screenHeight][screenWidth]bool, x: u8, y: u8, enabled: bool) void {
    buffer[x][y] = enabled;
}
