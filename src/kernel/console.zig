const std = @import("std");

const sharedModule = @import("shared");
const GOPWrapper = sharedModule.graphics.GOPWrapper;

const fontData = @import("libfont");
const GLYPH_MAP = fontData.GLYPH_MAP;
const GLYPH_WIDTH = fontData.GLYPH_WIDTH;
const GLYPH_HEIGHT = fontData.GLYPH_HEIGHT;
const Glyph = fontData.Glyph;

var line_number: u32 = 0;
var line_x: u32 = 1;

pub const WriterType = std.io.GenericWriter(*GOPWrapper, error{InvalidUtf8}, writerCallback);

pub fn setupConsole(gop_wrapper: *GOPWrapper) WriterType {
    return .{.context = gop_wrapper};
}

pub fn reset() void {
    line_number = 0;
    line_x = 1;
}

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

pub fn puts(gop: *GOPWrapper, text: []const u8) !void {
    const view = try std.unicode.Utf8View.init(text);
    var it = view.iterator();
    while (it.nextCodepoint()) |codepoint| {
        if(codepoint >= 256) continue;
        switch (codepoint) {
            '\r' => {
                line_x = 1;
                continue;
            },
            '\n' => {
                increaseLineNumber(gop.info.vertical_resolution);
                line_x = 1;
                continue;
            },
            ' ' => {
                line_x += GLYPH_WIDTH;
            },

            else => {
                const glyph = GLYPH_MAP[codepoint];
                if (glyph.isZero()) continue;
                putchar(gop, glyph, line_x, line_number);
                line_x += glyph.size;
            }
        }
        if (line_x + GLYPH_WIDTH >= gop.info.horizontal_resolution) {
            line_x = 1;
            increaseLineNumber(gop.info.vertical_resolution);
        }
    }
}

fn increaseLineNumber(max_vert_size: u32) void {
    line_number += 1;
    if ((line_number + 1) * GLYPH_HEIGHT >= max_vert_size) {
        line_number = 0;
    }
}

fn writerCallback(gop: *GOPWrapper, out: []const u8) !usize {
    try puts(gop, out);
    return out.len;
}