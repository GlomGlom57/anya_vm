const sc = @import("screen.zig");

const Opcode = enum(u8) {
    // Memory
    LOAD = 0x00,
    STORE = 0x01,

    // Math
    ADD = 0x02,
    SUB = 0x03,
    MPL = 0x04,
    DIV = 0x05,

    // Jumps
    JMP = 0x06,
    JMP_P = 0x07,
    JMP_N = 0x08,
    JMP_Z = 0x09,
    JMP_NZ = 0x0A,

    // Screen
    CLEAR = 0x0B,
    SHOW = 0x0C,
    PIX_ON = 0x0D,
    PIX_OFF = 0x0E,

    // Game
    WAIT = 0x0F,
    RECV = 0x10,
    END = 0x11,

    // Keyboard
    //  Movement
    LFT = 0x12,
    RGT = 0x13,
    UP = 0x14,
    DWN = 0x15,

    //  Actions
    BTA = 0x16,
    BTB = 0x17,
    BTC = 0x18,
    BTD = 0x19,
    SPC = 0x1A,
};

fn exec_instruction() !void {}

pub fn exec_game() !void {}
