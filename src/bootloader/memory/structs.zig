const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

pub const MemoryRegions = @import("shared").memory.MemoryRegions;


pub const VirtualMapData = struct {
    vmap: uefi.tables.MemoryMapSlice,
    conventional_region: MemoryRegions
};