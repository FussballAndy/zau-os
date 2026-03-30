const std = @import("std");
const uefi = std.os.uefi;
const log = @import("./log.zig");
const loader = @import("./image/index.zig");

const exec = @import("./image/executor.zig");

const graphics = @import("./graphics.zig");

const GOPWrapper = @import("shared").graphics.GOPWrapper;
const heap = @import("./heap.zig");

pub fn main() uefi.Error!void {
    try log.putsln("Welcome from the Bootloader!");

    inner_main() catch |err| {
        log.print("Result: {s}\r\n", .{@errorName(err)});
    };

    log.putslnErr("\r\n"); // Padding
}

fn inner_main() uefi.Error!void {
    const boot: *uefi.tables.BootServices = uefi.system_table.boot_services orelse {
        log.putslnErr("Failed to load boot services");
        return uefi.Error.Unsupported;
    };

    var buffer_alloc = try heap.allocateHeap(boot);
    const allocator = buffer_alloc.allocator();

    log.putslnErr("Loading file handles.");

    var kernel_data = try loader.loadKernelFromDisk(boot, allocator);

    log.putslnErr("Success.");
    log.putslnErr("Loading and setting up GOP.");

    const gop = try graphics.getGOP(boot);
    var gop_wrapper = try graphics.setupGOP(gop);

    log.putslnErr("Success.");
    log.putslnErr("Starting kernel. Have fun");

    return exec.startKernel(boot, allocator, &kernel_data, &gop_wrapper);
}
