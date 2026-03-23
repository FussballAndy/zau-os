const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

const MemoryInfo = @import("./structs.zig").MemoryInfo;

const log = @import("../log.zig");


pub fn getMemoryInfo(boot: *uefi.tables.BootServices, allocator: std.mem.Allocator) uefi.Error!uefi.tables.MemoryMapSlice {
    const mmap_info = boot.getMemoryMapInfo() catch |err| {
        log.putslnErr("Failed to get memory map info.");
        return err;
    };

    log.print("prelim key: {}\r\n", .{@intFromEnum(mmap_info.key)});

    // we do not need to allocate more than mmap_size Elements, as the heap is already allocated thus the allocation
    // does not change the memory map
    const mmap_buffer = allocator.alignedAlloc(u8, std.mem.Alignment.fromByteUnits(@alignOf(MemoryDescriptor)), mmap_info.len * mmap_info.descriptor_size) catch {
        log.putslnErr("Failed to allocate memory map buffer.");
        return uefi.Error.OutOfResources;
    };

    return boot.getMemoryMap(mmap_buffer) catch |err| {
        log.putslnErr("Failed to get memory map with allocated buffer.");
        return err;
    };
}
