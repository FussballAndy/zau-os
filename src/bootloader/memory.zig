const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

const UefiResult = @import("./status.zig").UefiResult;
const Result = UefiResult(MemoryInfo);

const log = @import("./log.zig");

pub const MemoryInfo = struct {
    /// Note that this is less of an actual array as we use it in zig and rather just the pointer
    /// to the base of the memory descriptors. Problem is that the descriptor size does not necessarily
    /// match @sizeOf(MemoryDescriptor) and thus indexing memory_map would lead to undefined behavior.
    /// Thus we simply store a base pointer and get the individual entries by indexing the manual way.
    /// See also MemoryMapIterator
    memory_map: [*]const MemoryDescriptor,
    memory_map_size: usize,
    map_key: usize,
    descriptor_size: usize,
    descriptor_version: u32,

    const Self = @This();

    pub fn memoryMapIterator(self: Self) MemoryMapIterator {
        return MemoryMapIterator{
            .base = self.memory_map,
            .memory_map_size = self.memory_map_size,
            .i = 0,
            .descriptor_size = self.descriptor_size,
        };
    }
};

pub const MemoryMapIterator = struct {
    base: [*]const MemoryDescriptor,
    memory_map_size: usize,
    i: usize,
    descriptor_size: usize,

    const Self = @This();

    pub fn next(self: *Self) ?*MemoryDescriptor {
        const index = self.i * self.descriptor_size;
        if(index < self.memory_map_size) {
            const address = @intFromPtr(self.base) + index;
            self.i += 1;
            return @ptrFromInt(address);
        }
        return null;
    }
};

pub fn getMemoryInfo(boot: *uefi.tables.BootServices) Result {
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

    const memory_map_capacity = mmap_size + 2 * desc_size;
    mmap_size = memory_map_capacity;
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

    return Result{.ok = MemoryInfo{
        .memory_map = mmap.?,
        .memory_map_size = mmap_size,
        .map_key = mmap_key,
        .descriptor_size = desc_size,
        .descriptor_version = desc_version,
    }};
}
