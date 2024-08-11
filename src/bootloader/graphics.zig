const std = @import("std");
const uefi = std.os.uefi;
const BootServices = uefi.tables.BootServices;
const GOP = uefi.protocol.GraphicsOutput;

const statusMod = @import("./status.zig");
const Result = statusMod.UefiResult(*GOP);
const isError = statusMod.isError;

const log = @import("./log.zig");

const graphics = @import("shared").graphics;
const GOPWrapper = graphics.GOPWrapper;

pub fn getGOP(boot: *BootServices) Result {
    var guid align(8) = GOP.guid;
    var gop_raw: ?*GOP = null;
    // ptrCast SAFETY: *?*GOP -> *?*anyopaque
    const status = boot.locateProtocol(&guid, null, @ptrCast(&gop_raw));
    if(isError(status)) {
        log.putslnErr("Couldn't locate GOP.");
        return Result{.err = status};
    }
    const gop = gop_raw orelse return Result{.err = uefi.Status.Unsupported};
    return Result{.ok = gop};
}

pub fn setupGOP(gop: *GOP) statusMod.UefiResult(GOPWrapper) {
    
    var size_of_info: usize = 0;
    var info: *GOP.Mode.Info = undefined;
    const status = gop.queryMode(gop.mode.mode, &size_of_info, &info);
    if(isError(status)) {
        log.putslnErr("Failed to query GOP mode.");
        return .{.err = status};
    }
    log.print("Current Mode: {}/{}\r\n", .{gop.mode.mode, gop.mode.max_mode});
    log.print("Width x Height: {}/{}\r\n", .{info.horizontal_resolution, info.vertical_resolution});
    log.print("Framebuffer address, size: {x}, {x}\r\n", .{gop.mode.frame_buffer_base, gop.mode.frame_buffer_size});
    log.print("PixelFormat: {}\r\n", .{info.pixel_format});
    log.print("PixelsPerScanLine: {}\r\n", .{info.pixels_per_scan_line});


    const wrapper = GOPWrapper{
        // SAFETY: Mode.frame_buffer_base stores the base address of the framebuffer
        .framebuffer = @ptrFromInt(gop.mode.frame_buffer_base),
        .info = info.*,
    };

    return .{.ok = wrapper};
}
