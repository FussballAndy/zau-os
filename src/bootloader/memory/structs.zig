const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;

pub const MemoryRegions = @import("shared").memory.MemoryRegions;

pub const MemoryInfo = struct {
    /// Note that this is less of an actual array as we use it in zig and rather just the pointer
    /// to the base of the memory descriptors. Problem is that the descriptor size does not necessarily
    /// match @sizeOf(MemoryDescriptor) and thus indexing memory_map would lead to undefined behavior.
    /// Thus we simply store a base pointer and get the individual entries by indexing the manual way.
    /// See also MemoryMapIterator
    memory_map: [*]MemoryDescriptor,
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
            // SAFETY: address has a valid offset (multiple of descriptor_size) from base
            return @ptrFromInt(address);
        }
        return null;
    }
};

pub const VirtualMapData = struct {
    virtual_map: MemoryInfo,
    conventional_region: MemoryRegions
};