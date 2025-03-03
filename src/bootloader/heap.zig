const std = @import("std");
const uefi = std.os.uefi;

const Result = @import("./status.zig").UefiResult;
const log = @import("./log.zig");

pub fn allocateHeap(boot: *uefi.tables.BootServices) Result(std.heap.FixedBufferAllocator) {
    const heap_size = 4 * 1024 * 1024; // 4 MB
    const heap_pages = heap_size / 4096;
    var heap: [*]align(4096) u8 = undefined;
    const status = boot.allocatePages(.AllocateAnyPages, uefi.tables.MemoryType.LoaderData, heap_pages, &heap);
    if(status != .Success) {
        log.putslnErr("Failed to allocate heap");
        const tag_name = std.enums.tagName(uefi.Status, status);
        log.print("Result: {?s}", .{tag_name});
        return status;
    }
    defer _ = boot.freePages(heap, heap_pages);
    const heap_slice = heap[0..heap_size];
    return std.heap.FixedBufferAllocator.init(heap_slice);
}