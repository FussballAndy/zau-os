const std = @import("std");
const uefi = std.os.uefi;
const GOP = uefi.protocol.GraphicsOutput;

pub const Color = extern struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0
};

pub const GOPWrapper = extern struct {
    info: GOP.Mode.Info,
    framebuffer: [*]u32,

    const Self = @This();

    pub fn setPixel(self: *Self, x: usize, y: usize, pixel: Color) void {
        const colorCode = applyFormatOnColor(self.info.pixel_format, pixel);
        self.framebuffer[self.info.pixels_per_scan_line * y + x] = colorCode;
    }

    fn applyFormatOnColor(format: GOP.PixelFormat, pixel: Color) u32 {
        var result: u32 = 0;
        switch (format) {
            .RedGreenBlueReserved8BitPerColor => {
                result = pixel.red;
                result |= (@as(u32, pixel.green) << 8);
                result |= (@as(u32, pixel.blue) << 16);
            },
            .BlueGreenRedReserved8BitPerColor => {
                result = pixel.blue;
                result |= (@as(u32, pixel.green) << 8);
                result |= (@as(u32, pixel.red) << 16);
            },
            else => {}
        }
        return result;
    }
};
