const rl = @import("raylib");

fn set_button(btns: *u16, btn: *u4) void {
    btns.* |= @as(u16, 1) << btn;
}

pub fn is_pressed(btns: *u16, btn: *u4) bool {
    return (btns & (@as(u16, 1) << btn)) != 0;
}

pub fn read_buttons(btns: *u16, milis: *u16) void {}
