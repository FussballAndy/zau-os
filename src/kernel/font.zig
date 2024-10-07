const std = @import("std");

pub const GLYPH_WIDTH = 8;
pub const GLYPH_HEIGHT = 13;

pub const Glyph = struct {
    lower: u64,
    higher: u64,
    size: u8,

    pub fn hasPixel(self: Glyph, x: u32, y: u32) bool {
        const index = y * self.size + x;
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
    INNER[' '] = .{.size = 5, .lower = 0x0, .higher = 0x0};
    INNER['!'] = .{.size = 2, .lower = 0x115500, .higher = 0x0};
    INNER['"'] = .{.size = 4, .lower = 0x550000, .higher = 0x0};
    INNER['#'] = .{.size = 6, .lower = 0xa7ca29f280000000, .higher = 0x0};
    INNER['$'] = .{.size = 6, .lower = 0x43d4385784000000, .higher = 0x0};
    INNER['%'] = .{.size = 6, .lower = 0x96421084d3000000, .higher = 0x1};
    INNER['&'] = .{.size = 7, .lower = 0x910c285040000000, .higher = 0xb88};
    INNER['\''] = .{.size = 2, .lower = 0x500, .higher = 0x0};
    INNER['('] = .{.size = 3, .lower = 0x44924a000, .higher = 0x0};
    INNER[')'] = .{.size = 3, .lower = 0x292491000, .higher = 0x0};
    INNER['*'] = .{.size = 4, .lower = 0x5250000, .higher = 0x0};
    INNER['+'] = .{.size = 6, .lower = 0x1047c4100000000, .higher = 0x0};
    INNER[','] = .{.size = 3, .lower = 0x280000000, .higher = 0x0};
    INNER['-'] = .{.size = 6, .lower = 0x7c0000000000, .higher = 0x0};
    INNER['.'] = .{.size = 2, .lower = 0x100000, .higher = 0x0};
    INNER['/'] = .{.size = 4, .lower = 0x11222440000, .higher = 0x0};
    INNER['0'] = .{.size = 6, .lower = 0xe45145144e000000, .higher = 0x0};
    INNER['1'] = .{.size = 6, .lower = 0xf104104184000000, .higher = 0x1};
    INNER['2'] = .{.size = 6, .lower = 0xf08421044e000000, .higher = 0x1};
    INNER['3'] = .{.size = 6, .lower = 0xe45031044e000000, .higher = 0x0};
    INNER['4'] = .{.size = 6, .lower = 0x821f24a308000000, .higher = 0x0};
    INNER['5'] = .{.size = 6, .lower = 0xf41040f05f000000, .higher = 0x0};
    INNER['6'] = .{.size = 6, .lower = 0xe45144f04e000000, .higher = 0x0};
    INNER['7'] = .{.size = 6, .lower = 0x410821041f000000, .higher = 0x0};
    INNER['8'] = .{.size = 6, .lower = 0xe45139144e000000, .higher = 0x0};
    INNER['9'] = .{.size = 6, .lower = 0xe41e45144e000000, .higher = 0x0};
    INNER[':'] = .{.size = 2, .lower = 0x104000, .higher = 0x0};
    INNER[';'] = .{.size = 3, .lower = 0x280400000, .higher = 0x0};
    INNER['<'] = .{.size = 4, .lower = 0x4212400000, .higher = 0x0};
    INNER['='] = .{.size = 5, .lower = 0xf03c0000000, .higher = 0x0};
    INNER['>'] = .{.size = 4, .lower = 0x1242100000, .higher = 0x0};
    INNER['?'] = .{.size = 6, .lower = 0x400421044e000000, .higher = 0x0};
    INNER['@'] = .{.size = 6, .lower = 0xe05d55d44e000000, .higher = 0x1};
    INNER['A'] = .{.size = 6, .lower = 0x145f45144e000000, .higher = 0x1};
    INNER['B'] = .{.size = 6, .lower = 0xf45144f44f000000, .higher = 0x0};
    INNER['C'] = .{.size = 6, .lower = 0xe04104109c000000, .higher = 0x1};
    INNER['D'] = .{.size = 6, .lower = 0xf451451247000000, .higher = 0x0};
    INNER['E'] = .{.size = 6, .lower = 0xe04104f05e000000, .higher = 0x1};
    INNER['F'] = .{.size = 6, .lower = 0x104104f05e000000, .higher = 0x0};
    INNER['G'] = .{.size = 6, .lower = 0xe45174144e000000, .higher = 0x0};
    INNER['H'] = .{.size = 6, .lower = 0x145145f451000000, .higher = 0x1};
    INNER['I'] = .{.size = 6, .lower = 0xf10410411f000000, .higher = 0x1};
    INNER['J'] = .{.size = 6, .lower = 0x721041041f000000, .higher = 0x0};
    INNER['K'] = .{.size = 6, .lower = 0x14491c9451000000, .higher = 0x1};
    INNER['L'] = .{.size = 6, .lower = 0xe041041041000000, .higher = 0x1};
    INNER['M'] = .{.size = 8, .lower = 0x4949493600000000, .higher = 0x414949};
    INNER['N'] = .{.size = 6, .lower = 0x1451451247000000, .higher = 0x1};
    INNER['O'] = .{.size = 6, .lower = 0xe45145144e000000, .higher = 0x0};
    INNER['P'] = .{.size = 6, .lower = 0x104f45144f000000, .higher = 0x0};
    INNER['Q'] = .{.size = 6, .lower = 0x625545144e000000, .higher = 0x1};
    INNER['R'] = .{.size = 6, .lower = 0x144f45144f000000, .higher = 0x1};
    INNER['S'] = .{.size = 6, .lower = 0xf41038105e000000, .higher = 0x0};
    INNER['T'] = .{.size = 6, .lower = 0x410410411f000000, .higher = 0x0};
    INNER['U'] = .{.size = 6, .lower = 0xe451451451000000, .higher = 0x0};
    INNER['V'] = .{.size = 6, .lower = 0x4291451451000000, .higher = 0x0};
    INNER['W'] = .{.size = 8, .lower = 0x4949414100000000, .higher = 0x364949};
    INNER['X'] = .{.size = 6, .lower = 0x144a10a451000000, .higher = 0x1};
    INNER['Y'] = .{.size = 6, .lower = 0x4104291451000000, .higher = 0x0};
    INNER['Z'] = .{.size = 6, .lower = 0xf04210841f000000, .higher = 0x1};
    INNER['['] = .{.size = 3, .lower = 0x64924b000, .higher = 0x0};
    INNER['\\'] = .{.size = 4, .lower = 0x44222110000, .higher = 0x0};
    INNER[']'] = .{.size = 3, .lower = 0x692493000, .higher = 0x0};
    INNER['^'] = .{.size = 6, .lower = 0x11284000000, .higher = 0x0};
    INNER['_'] = .{.size = 6, .lower = 0xf000000000000000, .higher = 0x1};
    INNER['`'] = .{.size = 3, .lower = 0x11000, .higher = 0x0};
    INNER['a'] = .{.size = 6, .lower = 0xe45e40e000000000, .higher = 0x1};
    INNER['b'] = .{.size = 6, .lower = 0xf45144f041000000, .higher = 0x0};
    INNER['c'] = .{.size = 5, .lower = 0x38210b80000000, .higher = 0x0};
    INNER['d'] = .{.size = 6, .lower = 0xe45145e410000000, .higher = 0x1};
    INNER['e'] = .{.size = 6, .lower = 0xe05f44e000000000, .higher = 0x0};
    INNER['f'] = .{.size = 5, .lower = 0x84213c4c00000, .higher = 0x0};
    INNER['g'] = .{.size = 6, .lower = 0xe45144e000000000, .higher = 0xe41};
    INNER['h'] = .{.size = 6, .lower = 0x145144f041000000, .higher = 0x1};
    INNER['i'] = .{.size = 3, .lower = 0x924c2000, .higher = 0x0};
    INNER['j'] = .{.size = 4, .lower = 0x3444446040000, .higher = 0x0};
    INNER['k'] = .{.size = 5, .lower = 0x24a32a42100000, .higher = 0x0};
    INNER['l'] = .{.size = 3, .lower = 0x89249000, .higher = 0x0};
    INNER['m'] = .{.size = 8, .lower = 0x4b3d000000000000, .higher = 0x494949};
    INNER['n'] = .{.size = 6, .lower = 0x14514cd000000000, .higher = 0x1};
    INNER['o'] = .{.size = 6, .lower = 0xe45144e000000000, .higher = 0x0};
    INNER['p'] = .{.size = 6, .lower = 0xf45144f000000000, .higher = 0x104};
    INNER['q'] = .{.size = 6, .lower = 0xe45145e000000000, .higher = 0x1041};
    INNER['r'] = .{.size = 5, .lower = 0x4211b40000000, .higher = 0x0};
    INNER['s'] = .{.size = 6, .lower = 0xf40e05e000000000, .higher = 0x0};
    INNER['t'] = .{.size = 5, .lower = 0x304213c4200000, .higher = 0x0};
    INNER['u'] = .{.size = 6, .lower = 0x6651451000000000, .higher = 0x1};
    INNER['v'] = .{.size = 6, .lower = 0x4291451000000000, .higher = 0x0};
    INNER['w'] = .{.size = 8, .lower = 0x4941000000000000, .higher = 0x364949};
    INNER['x'] = .{.size = 6, .lower = 0x1284291000000000, .higher = 0x1};
    INNER['y'] = .{.size = 6, .lower = 0xe451451000000000, .higher = 0xe41};
    INNER['z'] = .{.size = 6, .lower = 0xf08421f000000000, .higher = 0x1};
    INNER['{'] = .{.size = 4, .lower = 0x622232260000, .higher = 0x0};
    INNER['|'] = .{.size = 2, .lower = 0x155500, .higher = 0x0};
    INNER['}'] = .{.size = 4, .lower = 0x322262230000, .higher = 0x0};
    INNER['~'] = .{.size = 6, .lower = 0x8542000000000, .higher = 0x0};

    break :t INNER;
};