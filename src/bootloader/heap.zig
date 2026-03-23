const std = @import("std");
const uefi = std.os.uefi;

const log = @import("./log.zig");

pub fn allocateHeap(boot: *uefi.tables.BootServices) uefi.Error!std.heap.FixedBufferAllocator {
    const heap_size = 4 * 1024 * 1024; // 4 MB
    const heap_pages = heap_size / 4096;
    const heap = boot.allocatePages(.any, .loader_data, heap_pages) catch |err| {
        log.putslnErr("Failed to allocate heap");
        log.print("Result: {s}", .{@errorName(err)});
        return err;
    };
    
    // defer _ = boot.freePages(heap, heap_pages); why is this here?
    const heap_raw: []u8 = @ptrCast(heap);
    const heap_slice = heap_raw[0..heap_size];
    return std.heap.FixedBufferAllocator.init(heap_slice);
}