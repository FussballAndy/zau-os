const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const Allocator = std.mem.Allocator;

const memory_structs = @import("./structs.zig");
const MemoryInfo = memory_structs.MemoryInfo;
const VirtualMapData = memory_structs.VirtualMapData;
const MemoryRegions = memory_structs.MemoryRegions;

/// Build the memory map for virtual memory.
/// 
/// The resulting map will be structured as follows:
/// - All non conventional (reserved) blocks will stay at the same address (`virtual = physical`)
/// - All conventional blocks get grouped together and build a single block starting at (`max(physical+pages*page_size)`)
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
        if(mem_desc.type == .conventional_memory) {
            mem_desc.virtual_start = current_base;
            current_base += mem_desc.number_of_pages * 4096;
        } else {
            mem_desc.virtual_start = mem_desc.physical_start;
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
        .conventional_region = MemoryRegions{
            .usable_memory_start = convential_start,
            .usable_memory_end = current_base,
        }
    };
}

fn findMaxReservedAddress(memory_info: *MemoryInfo) usize {
    var it = memory_info.memoryMapIterator();
    var max: usize = 0;
    while (it.next()) |mem_desc| {
        if (mem_desc.attribute.memory_runtime and mem_desc.type != .conventional_memory) {
            max = @max(max, mem_desc.physical_start + mem_desc.number_of_pages * 4096);
        }
    }
    return max;
}

/// Update pointers given virtual map
/// 
/// `change_pointers` should be a tuple of `**anytype`. This will modify the inner
/// `*anytype` to point to the new virtual location
pub fn updatePointers(memory_info: *MemoryInfo, change_pointers: anytype) void {
    var mmap_iter = memory_info.memoryMapIterator();
    while (mmap_iter.next()) |mem_desc| {
        if(!mem_desc.attribute.memory_runtime) continue;
        const physical_start = mem_desc.physical_start;
        const physical_size = mem_desc.number_of_pages * 4096;
        const physical_end = physical_start + physical_size;

        const cp_type_info = @typeInfo(@TypeOf(change_pointers));
        if(cp_type_info == .@"struct" and cp_type_info.@"struct".is_tuple) {
            inline for (cp_type_info.@"struct".fields) |field| {
                const field_info = @typeInfo(field.type);
                if(field_info != .pointer) {
                    @compileError("change_pointer doesn't have corret type. Expected '**any'");
                }
                const ifield_info = @typeInfo(field_info.pointer.child);
                
                if(ifield_info != .pointer) {
                    @compileError("change_pointer doesn't have corret type. Expected '**any'");
                }
                const PT = field_info.pointer.child;
                const val: *PT = @field(change_pointers, field.name);
                const deref_val: PT = val.*; // Literal dereference so that compiler does not do weird inference
                const val_address = @intFromPtr(deref_val);
                if(physical_start <= val_address and val_address < physical_end) {
                    const new_ptr: PT = @ptrFromInt(val_address - physical_start + mem_desc.virtual_start);
                    val.* = new_ptr;
                }
            }
        } else {
            @compileError("Expected change_pointers to be a tuple struct!");
        }

    }
}