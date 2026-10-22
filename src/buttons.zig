const rl = @import("raylib");

const rows = 4;
const cols = 4;
const buttons = .{ .{ .one, .two, .three, .four }, .{ .q, .w, .e, .r }, .{ .a, .s, .d, .f }, .{ .z, .x, .c, .v } };

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

pub fn is_pressed(btns: u16, btn: u4) bool {
    return (btns & (@as(u16, 1) << btn)) != 0;
}

pub fn clear_pressed(btns: *u16) void {
    btns.* = 0;
}

pub fn read_buttons(btns: *u16, milis: u16) void {
    const last_time = rl.getTime();

    while ((rl.getTime() - last_time) * 1000.0 < milis) {
        var bit_index: u4 = 0;
        inline for (0..rows) |row| {
            inline for (0..cols) |col| {
                if (rl.isKeyPressed(buttons[row][col])) {
                    set_button(btns, bit_index);
                }
                bit_index += 1; // 1 2 3 | 5 6 7 | 9 10 11 | 13 14 15
            }

            bit_index += 1; // 4 8 12
        }
    }
}
