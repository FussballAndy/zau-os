const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

const MemoryInfo = @import("./structs.zig").MemoryInfo;

const UefiResult = @import("../status.zig").UefiResult;
const Result = UefiResult(MemoryInfo);

const log = @import("../log.zig");


pub fn getMemoryInfo(boot: *uefi.tables.BootServices, allocator: std.mem.Allocator) Result {
    var mmap: ?[*]MemoryDescriptor = null;
    var mmap_size: usize = 0;
    var mmap_key: usize = 0;
    var desc_size: usize = 0;
    var desc_version: u32 = 0;
    var status = boot.getMemoryMap(&mmap_size, mmap, &mmap_key, &desc_size, &desc_version);
    if(status != .BufferTooSmall) {
        log.putslnErr("getMemoryMap() didn't return BufferTooSmall, aborting");
        return Result{.err = status};
    }

    // we do not need to allocate more than mmap_size Elements, as the heap is already allocated thus the allocation
    // does not change the memory map
    const mmap_slice: []align(8) u8 = allocator.alignedAlloc(u8, 8, mmap_size) catch {
        log.putslnErr("Failed to allocate memory map buffer.");
        return Result{.err = .OutOfResources};
    };
    // ptrCast SAFETY: [*]u8 -> [*]MemoryDescriptor, u8 has size multiple of memory descriptor size.
    mmap = @ptrCast(mmap_slice.ptr);
    status = boot.getMemoryMap(&mmap_size, mmap, &mmap_key, &desc_size, &desc_version);
    if(status != .Success) {
        log.putslnErr("Failed to getMemoryMap() with an initialized buffer.");
        return Result{.err = status};
    }

    return Result{.ok = MemoryInfo{
        .memory_map = mmap.?,
        .memory_map_size = mmap_size,
        .map_key = mmap_key,
        .descriptor_size = desc_size,
        .descriptor_version = desc_version,
    }};
}
