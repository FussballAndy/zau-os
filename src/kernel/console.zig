const std = @import("std");

const sharedModule = @import("shared");
const GOPWrapper = sharedModule.graphics.GOPWrapper;

const fontData = @import("libfont");
const GLYPH_MAP = fontData.GLYPH_MAP;
const GLYPH_WIDTH = fontData.GLYPH_WIDTH;
const GLYPH_HEIGHT = fontData.GLYPH_HEIGHT;
const Glyph = fontData.Glyph;

const WriterContext = struct {
    line_number: u32 = 0,
    line_x: u32 = 1,
    gop_wrapper: *GOPWrapper,

    pub fn increaseLineNumber(self: *WriterContext) void {
        self.line_number += 1;
        if ((self.line_number + 1) * GLYPH_HEIGHT >= self.gop_wrapper.info.vertical_resolution) {
            self.line_number = 0;
        }
    }

    pub inline fn putChar(self: *WriterContext, char: Glyph) void {
        putchar(self.gop_wrapper, char, self.line_x, self.line_number);
    }
};

const WriterType = std.io.GenericWriter(*WriterContext, error{InvalidUtf8}, writerCallback);

pub const Console = struct {
    context: WriterContext,

    pub fn new(gop_wrapper: *GOPWrapper) Console {
        return .{
            .context = .{.gop_wrapper = gop_wrapper},
        };
    }

    pub fn writer(self: *Console) WriterType {
        return .{ .context = &self.context };
    }

    pub inline fn print(self: *Console, comptime format: []const u8, args: anytype) !void {
        return self.writer().print(format, args);
    }

    pub fn reset(self: *Console) void {
        self.context.line_number = 0;
        self.context.line_x = 1;
    }
};

fn putchar(gop: *GOPWrapper, char: Glyph, screen_x: u32, cy: u32) void {
    // Assumes valid char
    const screen_y = cy * GLYPH_HEIGHT;
    for (0..GLYPH_HEIGHT) |y| {
        for (0..char.size) |x| {
            if(char.hasPixel(@intCast(x), @intCast(y))) {
                gop.setPixel(screen_x + x, screen_y + y, .{.red = 255, .green = 255, .blue = 255});
            }
        }
    }
}

fn puts(ctx: *WriterContext, text: []const u8) !void {
    const view = try std.unicode.Utf8View.init(text);
    var it = view.iterator();
    while (it.nextCodepoint()) |codepoint| {
        if(codepoint >= 256) continue;
        switch (codepoint) {
            '\r' => {
                ctx.line_x = 1;
                continue;
            },
            '\n' => {
                ctx.increaseLineNumber();
                ctx.line_x = 1;
                continue;
            },
            ' ' => {
                ctx.line_x += GLYPH_WIDTH;
            },

            else => {
                const glyph = GLYPH_MAP[codepoint];
                if (glyph.isZero()) continue;
                ctx.putChar(glyph);
                ctx.line_x += glyph.size;
            }
        }
        if (ctx.line_x + GLYPH_WIDTH >= ctx.gop_wrapper.info.horizontal_resolution) {
            ctx.line_x = 1;
            ctx.increaseLineNumber();
        }
    }
}

fn writerCallback(ctx: *WriterContext, out: []const u8) !usize {
    try puts(ctx, out);
    return out.len;
}