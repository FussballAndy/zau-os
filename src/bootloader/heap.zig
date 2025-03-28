const std = @import("std");
const uefi = std.os.uefi;

const Result = @import("./status.zig").UefiResult;
const log = @import("./log.zig");

pub fn allocateHeap(boot: *uefi.tables.BootServices) Result(std.heap.FixedBufferAllocator) {
    const heap_size = 4 * 1024 * 1024; // 4 MB
    const heap_pages = heap_size / 4096;
    var heap: [*]align(4096) u8 = undefined;
    const status = boot.allocatePages(.allocate_any_pages, uefi.tables.MemoryType.loader_data, heap_pages, &heap);
    if(status != .success) {
        log.putslnErr("Failed to allocate heap");
        const tag_name = std.enums.tagName(uefi.Status, status);
        log.print("Result: {?s}", .{tag_name});
        return .{.err = status};
    }
    defer _ = boot.freePages(heap, heap_pages);
    const heap_slice = heap[0..heap_size];
    return .{.ok = std.heap.FixedBufferAllocator.init(heap_slice)};
}