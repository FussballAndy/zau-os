const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const Allocator = std.mem.Allocator;

const MemoryInfo = @import("../memory_info.zig").MemoryInfo;

const shared = @import("shared");
const MemoryRegions = shared.memory.MemoryRegions;

pub const VirtualMapData = struct {
    virtual_map: MemoryInfo,
    conventional_region: MemoryRegions
};


pub fn buildVirtualMap(memory_info: *MemoryInfo, alloc: Allocator) !VirtualMapData {
    const desc_size = memory_info.descriptor_size;
    const virtual_map_bytes: []align(8) u8 = try alloc.alignedAlloc(u8, 8, memory_info.memory_map_size * desc_size);
    const virtual_map_ptr: [*]align(8) u8 = virtual_map_bytes.ptr;
    var virtual_map_item: usize = 0;

    const convential_start = findMaxReservedAddress(memory_info);
    var current_base = convential_start;

    var mmap_iter = memory_info.memoryMapIterator();
    while(mmap_iter.next()) |mem_desc| {
        if(!mem_desc.attribute.memory_runtime) continue;
        if(mem_desc.type == .ConventionalMemory) {
            mem_desc.virtual_start = current_base;
            current_base += mem_desc.number_of_pages * 4096;
        } else {
            mem_desc.virtual_start = mem_desc.virtual_start;
        }

        const virt_element_raw = virtual_map_ptr + virtual_map_item * desc_size; 
        // ptrCast SAFETY: virt_element_raw has a valid offset (multiple of descriptor_size) from base
        const virt_element: *MemoryDescriptor = @ptrCast(@alignCast(virt_element_raw));
        virt_element.* = mem_desc.*;
        virtual_map_item+=1;
    }

    const virt_mem_info = MemoryInfo{
        .map_key = 0,
        // ptrCast SAFETY: [*]align(8) u8 -> [*]MemoryDescriptor
        .memory_map = @ptrCast(virtual_map_ptr),
        .memory_map_size = virtual_map_item * memory_info.descriptor_size,
        .descriptor_size = memory_info.descriptor_size,
        .descriptor_version = memory_info.descriptor_version,
    };

    _ = alloc.resize(virtual_map_bytes, virt_mem_info.memory_map_size);

    return .{
        .virtual_map = virt_mem_info,
        .convetional_region = MemoryRegions{
            .usable_memory_start = convential_start,
            .usable_memory_end = current_base,
        }
    };
}

fn findMaxReservedAddress(memory_info: *MemoryInfo) usize {
    var it = memory_info.memoryMapIterator();
    var max: usize = 0;
    while (it.next()) |mem_desc| {
        if (mem_desc.attribute.memory_runtime and mem_desc.type != .ConventionalMemory) {
            max = @max(max, mem_desc.physical_start + mem_desc.number_of_pages * 4096);
        }
    }
    return max;
}