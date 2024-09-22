const std = @import("std");
const uefi = std.os.uefi;
const log = @import("./log.zig");
const statusTools = @import("./status.zig");
const loader = @import("./loader.zig");

const fs = @import("./fs.zig");

const exec = @import("./executor.zig");

const graphics = @import("./graphics.zig");

const GOPWrapper = @import("shared").graphics.GOPWrapper;

pub fn main() uefi.Status {
    var status = log.putsln("Welcome from the Bootloader!");
    if(status != .Success) {
        return status;
    }

    defer _ = log.putsln("\r\n"); // Padding

    const boot: *uefi.tables.BootServices = uefi.system_table.boot_services orelse {
        log.putslnErr("Failed to load boot services");
        return uefi.Status.Unsupported;
    };

    const heap_size = 4 * 1024 * 1024; // 64 MB
    const heap_pages = heap_size / 4096;
    var heap: [*]align(4096) u8 = undefined;
    status = boot.allocatePages(.AllocateAnyPages, uefi.tables.MemoryType.LoaderData, heap_pages, &heap);
    if(status != .Success) {
        log.putslnErr("Failed to allocate heap");
        const tag_name = std.enums.tagName(uefi.Status, status);
        log.print("Result: {?s}", .{tag_name});
        return status;
    }
    defer _ = boot.freePages(heap, heap_pages);
    const heap_slice = heap[0..heap_size];
    var buffer_alloc = std.heap.FixedBufferAllocator.init(heap_slice);
    const allocator = buffer_alloc.allocator();

    _ = log.putsln("Loading file handles.");

    const rootdir_result = fs.getRootDir(boot);
    if(rootdir_result == .err) {
        rootdir_result.printError();
        return rootdir_result.err;
    }
    const rootdir = rootdir_result.ok;

    _ = log.putsln("Success.");
    _ = log.putsln("Loading kernel into memory.");

    const kernel_data_raw = loader.loadKernel(boot, rootdir);
    if(kernel_data_raw == .err) {
        kernel_data_raw.printError();
        return kernel_data_raw.err;
    }
    var kernel_data = kernel_data_raw.ok;

    _ = log.putsln("Success.");
    _ = log.putsln("Loading and setting up GOP.");

    const gop_raw = graphics.getGOP(boot);
    if(gop_raw == .err) {
        gop_raw.printError();
        return gop_raw.err;
    }
    const gop = gop_raw.ok;
    const setup_result = graphics.setupGOP(gop);
    if(setup_result == .err) {
        setup_result.printError();
        return setup_result.err;
    }
    var gop_wrapper = setup_result.ok;

    _ = log.putsln("Success.");
    _ = log.putsln("Starting kernel. Have fun");

    status = exec.startKernel(boot, allocator, &kernel_data, &gop_wrapper);

    const tag_name = std.enums.tagName(uefi.Status, status);
    log.print("Result: {?s}", .{tag_name});

    return status;
}
