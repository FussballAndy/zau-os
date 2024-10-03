const std = @import("std");

pub const GLYPH_WIDTH = 8;
pub const GLYPH_HEIGHT = 13;

pub const Glyph = struct {
    lower: u64,
    higher: u64,
    size: u8,

    pub fn hasPixel(self: Glyph, x: u32, y: u32) bool {
        const index = x * GLYPH_HEIGHT + y;
        if(index >= 64) {
            const index2: u6 = @intCast(index - 64);
            const entry = self.higher & (@as(u64, 1) << index2);
            return entry != 0;
        }
        const index2: u6 = @intCast(index);
        const entry = self.lower & (@as(u64, 1) << index2);
        return entry != 0;
    }

    pub fn isZero(self: Glyph) bool {
        return self.size == 0;
    }

};

pub const GLYPH_MAP: [256]Glyph = t: {
    var INNER = std.mem.zeroes([256]Glyph);
    INNER['!'] = .{.size = 2, .lower = 0x5f0, .higher = 0x0};
    INNER['"'] = .{.size = 4, .lower = 0xc0000030, .higher = 0x0};
    INNER['#'] = .{.size = 6, .lower = 0x2403f00900fc0240, .higher = 0x0};
    INNER['$'] = .{.size = 6, .lower = 0x1201501fc0540240, .higher = 0x0};
    INNER['%'] = .{.size = 6, .lower = 0x6303200200260630, .higher = 0x0};
    INNER['&'] = .{.size = 7, .lower = 0x30023012409c0300, .higher = 0x800};
    INNER['\''] = .{.size = 2, .lower = 0x30, .higher = 0x0};
    INNER['('] = .{.size = 3, .lower = 0x10207e0, .higher = 0x0};
    INNER[')'] = .{.size = 3, .lower = 0xfc0810, .higher = 0x0};
    INNER['*'] = .{.size = 4, .lower = 0x140040050, .higher = 0x0};
    INNER['+'] = .{.size = 6, .lower = 0x800400f80100080, .higher = 0x0};
    INNER[','] = .{.size = 3, .lower = 0x800800, .higher = 0x0};
    INNER['-'] = .{.size = 6, .lower = 0x800400200100080, .higher = 0x0};
    INNER['.'] = .{.size = 2, .lower = 0x400, .higher = 0x0};
    INNER['/'] = .{.size = 4, .lower = 0xc0380600, .higher = 0x0};
    INNER['0'] = .{.size = 6, .lower = 0x3e020810408203e0, .higher = 0x0};
    INNER['1'] = .{.size = 6, .lower = 0x4002001fc0840400, .higher = 0x0};
    INNER['2'] = .{.size = 6, .lower = 0x4602481440c20420, .higher = 0x0};
    INNER['3'] = .{.size = 6, .lower = 0x3602481240820220, .higher = 0x0};
    INNER['4'] = .{.size = 6, .lower = 0x1003f80480280180, .higher = 0x0};
    INNER['5'] = .{.size = 6, .lower = 0x39022811408a0470, .higher = 0x0};
    INNER['6'] = .{.size = 6, .lower = 0x38022811408a03e0, .higher = 0x0};
    INNER['7'] = .{.size = 6, .lower = 0x700c81840020010, .higher = 0x0};
    INNER['8'] = .{.size = 6, .lower = 0x3602481240920360, .higher = 0x0};
    INNER['9'] = .{.size = 6, .lower = 0x3e02881440a200e0, .higher = 0x0};
    INNER[':'] = .{.size = 2, .lower = 0x480, .higher = 0x0};
    INNER[';'] = .{.size = 3, .lower = 0x900800, .higher = 0x0};
    INNER['<'] = .{.size = 4, .lower = 0x880280080, .higher = 0x0};
    INNER['='] = .{.size = 5, .lower = 0xa00500280140, .higher = 0x0};
    INNER['>'] = .{.size = 4, .lower = 0x200280220, .higher = 0x0};
    INNER['?'] = .{.size = 6, .lower = 0x600481440020020, .higher = 0x0};
    INNER['@'] = .{.size = 6, .lower = 0x5e02a817408203e0, .higher = 0x0};
    INNER['A'] = .{.size = 6, .lower = 0x7e008804402207e0, .higher = 0x0};
    INNER['B'] = .{.size = 6, .lower = 0x3a022811408a07f0, .higher = 0x0};
    INNER['C'] = .{.size = 6, .lower = 0x41020810408403c0, .higher = 0x0};
    INNER['D'] = .{.size = 6, .lower = 0x3c021010408207f0, .higher = 0x0};
    INNER['E'] = .{.size = 6, .lower = 0x41022811408a03e0, .higher = 0x0};
    INNER['F'] = .{.size = 6, .lower = 0x1002801400a07e0, .higher = 0x0};
    INNER['G'] = .{.size = 6, .lower = 0x3a024812408203e0, .higher = 0x0};
    INNER['H'] = .{.size = 6, .lower = 0x7f002001000807f0, .higher = 0x0};
    INNER['I'] = .{.size = 6, .lower = 0x4102081fc0820410, .higher = 0x0};
    INNER['J'] = .{.size = 6, .lower = 0x1f01081040820410, .higher = 0x0};
    INNER['K'] = .{.size = 6, .lower = 0x6300a002001007f0, .higher = 0x0};
    INNER['L'] = .{.size = 6, .lower = 0x40020010008003f0, .higher = 0x0};
    INNER['M'] = .{.size = 8, .lower = 0x101f000400207e0, .higher = 0x1f80020};
    INNER['N'] = .{.size = 6, .lower = 0x7c001000400207f0, .higher = 0x0};
    INNER['O'] = .{.size = 6, .lower = 0x3e020810408203e0, .higher = 0x0};
    INNER['P'] = .{.size = 6, .lower = 0xe008804402207f0, .higher = 0x0};
    INNER['Q'] = .{.size = 6, .lower = 0x5e010814408203e0, .higher = 0x0};
    INNER['R'] = .{.size = 6, .lower = 0x6e008804402207f0, .higher = 0x0};
    INNER['S'] = .{.size = 6, .lower = 0x3102481240920460, .higher = 0x0};
    INNER['T'] = .{.size = 6, .lower = 0x100081fc0020010, .higher = 0x0};
    INNER['U'] = .{.size = 6, .lower = 0x3f020010008003f0, .higher = 0x0};
    INNER['V'] = .{.size = 6, .lower = 0x1f010010004001f0, .higher = 0x0};
    INNER['W'] = .{.size = 8, .lower = 0x4001e010008003f0, .higher = 0xfc0800};
    INNER['X'] = .{.size = 6, .lower = 0x6300a00200280630, .higher = 0x0};
    INNER['Y'] = .{.size = 6, .lower = 0x700401c00100070, .higher = 0x0};
    INNER['Z'] = .{.size = 6, .lower = 0x4302281240a20610, .higher = 0x0};
    INNER['['] = .{.size = 3, .lower = 0x1020ff0, .higher = 0x0};
    INNER['\\'] = .{.size = 4, .lower = 0x1800380030, .higher = 0x0};
    INNER[']'] = .{.size = 3, .lower = 0x1fe0810, .higher = 0x0};
    INNER['^'] = .{.size = 6, .lower = 0x400100040040040, .higher = 0x0};
    INNER['_'] = .{.size = 6, .lower = 0x4002001000800400, .higher = 0x0};
    INNER['`'] = .{.size = 3, .lower = 0x40010, .higher = 0x0};
    INNER['a'] = .{.size = 6, .lower = 0x7802a01500a80200, .higher = 0x0};
    INNER['b'] = .{.size = 6, .lower = 0x38022011008807f0, .higher = 0x0};
    INNER['c'] = .{.size = 5, .lower = 0x2201100880380, .higher = 0x0};
    INNER['d'] = .{.size = 6, .lower = 0x7f02201100880380, .higher = 0x0};
    INNER['e'] = .{.size = 6, .lower = 0x1802a01500a80380, .higher = 0x0};
    INNER['f'] = .{.size = 5, .lower = 0x280140fc0040, .higher = 0x0};
    INNER['g'] = .{.size = 6, .lower = 0xf80a205102880380, .higher = 0x0};
    INNER['h'] = .{.size = 6, .lower = 0x78002001000807f0, .higher = 0x0};
    INNER['i'] = .{.size = 3, .lower = 0xfa0040, .higher = 0x0};
    INNER['j'] = .{.size = 4, .lower = 0x3f42081000, .higher = 0x0};
    INNER['k'] = .{.size = 5, .lower = 0x2200a002007f0, .higher = 0x0};
    INNER['l'] = .{.size = 3, .lower = 0x8003f0, .higher = 0x0};
    INNER['m'] = .{.size = 8, .lower = 0x403e001001007c0, .higher = 0x1e00080};
    INNER['n'] = .{.size = 6, .lower = 0x78002001001007c0, .higher = 0x0};
    INNER['o'] = .{.size = 6, .lower = 0x3802201100880380, .higher = 0x0};
    INNER['p'] = .{.size = 6, .lower = 0x3802201100881fc0, .higher = 0x0};
    INNER['q'] = .{.size = 6, .lower = 0xfc02201100880380, .higher = 0x1};
    INNER['r'] = .{.size = 5, .lower = 0x2001001007c0, .higher = 0x0};
    INNER['s'] = .{.size = 6, .lower = 0x2402a01500a80480, .higher = 0x0};
    INNER['t'] = .{.size = 5, .lower = 0x22011007e0040, .higher = 0x0};
    INNER['u'] = .{.size = 6, .lower = 0x7c010010008003c0, .higher = 0x0};
    INNER['v'] = .{.size = 6, .lower = 0x1c010010004001c0, .higher = 0x0};
    INNER['w'] = .{.size = 8, .lower = 0x4001c010008003c0, .higher = 0xf00800};
    INNER['x'] = .{.size = 6, .lower = 0x4401400400500440, .higher = 0x0};
    INNER['y'] = .{.size = 6, .lower = 0xfc0a0050028003c0, .higher = 0x0};
    INNER['z'] = .{.size = 6, .lower = 0x4402601500c80440, .higher = 0x0};
    INNER['{'] = .{.size = 4, .lower = 0x2041fe0080, .higher = 0x0};
    INNER['|'] = .{.size = 2, .lower = 0x7f0, .higher = 0x0};
    INNER['}'] = .{.size = 4, .lower = 0x201fe0810, .higher = 0x0};
    INNER['~'] = .{.size = 6, .lower = 0x800800200080080, .higher = 0x0};

    break :t INNER;
};