const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

const UefiResult = @import("./status.zig").UefiResult;
const Result = UefiResult(MemoryInfo);

const log = @import("./log.zig");

pub const MemoryInfo = struct {
    memory_map: []const MemoryDescriptor,
    map_key: usize,
    descriptor_size: usize,
    descriptor_version: u32,
};

pub fn getMemoryInfo(boot: *uefi.tables.BootServices) Result {
    var mmap: ?[*]uefi.tables.MemoryDescriptor = null;
    var mmap_size: usize = 0;
    var mmap_key: usize = 0;
    var desc_size: usize = 0;
    var desc_version: u32 = 0;
    var status = boot.getMemoryMap(&mmap_size, mmap, &mmap_key, &desc_size, &desc_version);
    if(status != .BufferTooSmall) {
        log.putslnErr("getMemoryMap() didn't return BufferTooSmall, aborting");
        return Result{.err = status};
    }

    const memory_map_capacity = mmap_size + 2 * desc_size;
    // ptrCast SAFETY: *?[*]MemoryDescriptor -> *[*]u8 should we add align(8) to mmap?
    status = boot.allocatePool(uefi.tables.MemoryType.LoaderData, memory_map_capacity, @ptrCast(&mmap));
    if(status != .Success or mmap == null) {
        log.putslnErr("Failed to allocate memory map buffer.");
        return Result{.err = status};
    }
    status = boot.getMemoryMap(&mmap_size, mmap, &mmap_key, &desc_size, &desc_version);
    if(status != .Success) {
        // ptrCast SAFETY: ?[*]MemoryDescriptor (guaranteed not null) -> [*]u8
        _ = boot.freePool(@ptrCast(mmap));
        log.putslnErr("Failed to getMemoryMap() with an initialized buffer.");
        return Result{.err = status};
    }

    const memory_map: []const MemoryDescriptor = mmap.?[0..mmap_size];
    return Result{.ok = MemoryInfo{
        .memory_map = memory_map,
        .map_key = mmap_key,
        .descriptor_size = desc_size,
        .descriptor_version = desc_version,
    }};
}
