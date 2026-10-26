const rl = @import("raylib");
const kb = rl.KeyboardKey;
const std = @import("std");

const rows = 4;
const cols = 4;
const buttons = .{ .{ kb.one, kb.two, kb.three, kb.four }, .{ kb.q, kb.w, kb.e, kb.r }, .{ kb.a, kb.s, kb.d, kb.f }, .{ kb.z, kb.x, kb.c, kb.v } };

const KR1C1 = 0;
const KR1C2 = 1;
const KR1C3 = 2;
const KR1C4 = 3;

const KR2C1 = 4;
const KR2C2 = 5;
const KR2C3 = 6;
const KR2C4 = 7;

const KR3C1 = 8;
const KR3C2 = 9;
const KR3C3 = 10;
const KR3C4 = 11;

const KR4C1 = 12;
const KR4C2 = 13;
const KR4C3 = 14;
const KR4C4 = 15;

fn set_button(btns: *u16, btn: u4) void {
    btns.* |= @as(u16, 1) << btn;
}

// The jumps happen if the user is NOT pressing the button
pub fn is_pressed(btns: u16, btn: u4) bool {
    return (btns & (@as(u16, 1) << btn)) == 0;
}

pub fn clear_pressed(btns: *u16) void {
    btns.* = 0;
}

pub fn read_buttons(btns: *u16, milis: u16) void {
    const last_time = rl.getTime();
    const wait_milis = @as(f64, @floatFromInt(milis)) / 1000.0;

    std.log.debug("------READING KEYS------", .{});
    while (rl.getTime() - last_time < wait_milis) {
        rl.pollInputEvents(); // Get events

        const pressed = rl.getKeyPressed();
        if (pressed == kb.null) continue;

        var bit_index: u4 = 0;

        inline for (0..rows) |row| {
            inline for (0..cols) |col| {
                if (pressed == buttons[row][col]) {
                    set_button(btns, bit_index);
                    std.log.debug("PRESSED: {}", .{buttons[row][col]});
                }
                if (bit_index < 15) bit_index += 1;
            }
        }
    }

    std.log.debug("------EXITED------", .{});
}
