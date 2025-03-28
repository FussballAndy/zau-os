const std = @import("std");
const uefi = std.os.uefi;
const log = @import("./log.zig");
const statusTools = @import("./status.zig");
const loader = @import("./loader.zig");

const fs = @import("./fs.zig");

const exec = @import("./executor.zig");

const graphics = @import("./graphics.zig");

const GOPWrapper = @import("shared").graphics.GOPWrapper;
const heap = @import("./heap.zig");

pub fn main() uefi.Status {
    var status = log.putsln("Welcome from the Bootloader!");
    if(status != .success) {
        return status;
    }

    status = inner_main();

    const tag_name = std.enums.tagName(uefi.Status, status);
    log.print("Result: {?s}\r\n", .{tag_name});

    _ = log.putsln("\r\n"); // Padding

    return status;
}

fn inner_main() uefi.Status {
    const boot: *uefi.tables.BootServices = uefi.system_table.boot_services orelse {
        log.putslnErr("Failed to load boot services");
        return uefi.Status.unsupported;
    };

    const heap_result = heap.allocateHeap(boot);
    if(heap_result == .err) {
        return heap_result.err;
    }
    var buffer_alloc = heap_result.ok;
    const allocator = buffer_alloc.allocator();

    _ = log.putsln("Loading file handles.");

    const rootdir_result = fs.getRootDir(boot);
    if(rootdir_result == .err) {
        return rootdir_result.err;
    }
    const rootdir = rootdir_result.ok;

    _ = log.putsln("Success.");
    _ = log.putsln("Loading kernel into memory.");

    const kernel_data_raw = loader.loadKernel(boot, rootdir);
    if(kernel_data_raw == .err) {
        return kernel_data_raw.err;
    }
    var kernel_data = kernel_data_raw.ok;

    _ = log.putsln("Success.");
    _ = log.putsln("Loading and setting up GOP.");

    const gop_raw = graphics.getGOP(boot);
    if(gop_raw == .err) {
        return gop_raw.err;
    }
    const gop = gop_raw.ok;
    const setup_result = graphics.setupGOP(gop);
    if(setup_result == .err) {
        return setup_result.err;
    }
    var gop_wrapper = setup_result.ok;

    _ = log.putsln("Success.");
    _ = log.putsln("Starting kernel. Have fun");

    return exec.startKernel(boot, allocator, &kernel_data, &gop_wrapper);
}
