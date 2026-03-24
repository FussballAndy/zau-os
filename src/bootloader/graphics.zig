const std = @import("std");
const uefi = std.os.uefi;
const BootServices = uefi.tables.BootServices;
const GOP = uefi.protocol.GraphicsOutput;

const log = @import("./log.zig");

const graphics = @import("shared").graphics;
const GOPWrapper = graphics.GOPWrapper;

pub fn getGOP(boot: *BootServices) uefi.Error!*GOP {
    // ptrCast SAFETY: *?*GOP -> *?*anyopaque
    const gop_raw = boot.locateProtocol(GOP, null) catch |err| {
        log.putslnErr("Couldn't locate GOP.");
        return err;
    };
    if (gop_raw) |gop| {
        return gop;
    } else {
        return uefi.Error.Unsupported;
    }
}

pub fn setupGOP(gop: *GOP) uefi.Error!GOPWrapper {
    const info = gop.queryMode(gop.mode.mode) catch |err| {
        log.putslnErr("Failed to query GOP mode.");
        return err;
    };
    log.print("Current Mode: {}/{}\r\n", .{ gop.mode.mode, gop.mode.max_mode });
    log.print("Width x Height: {}/{}\r\n", .{ info.horizontal_resolution, info.vertical_resolution });
    log.print("Framebuffer address, size: {x}, {x}\r\n", .{ gop.mode.frame_buffer_base, gop.mode.frame_buffer_size });
    log.print("PixelFormat: {}\r\n", .{info.pixel_format});
    log.print("PixelsPerScanLine: {}\r\n", .{info.pixels_per_scan_line});

    // SAFETY: Mode.frame_buffer_base stores the base address of the framebuffer
    const framebuffer_address: ?[*]u32 = @ptrFromInt(gop.mode.frame_buffer_base);
    if (framebuffer_address) |fb_address| {
        return .{
            .framebuffer = fb_address,
            .info = info.*,
        };
    } else {
        return uefi.Error.Unsupported;
    }
}
