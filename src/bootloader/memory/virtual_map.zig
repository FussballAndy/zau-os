const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const Allocator = std.mem.Allocator;

const memory_structs = @import("./structs.zig");
const VirtualMapData = memory_structs.VirtualMapData;
const MemoryRegions = memory_structs.MemoryRegions;

/// Build the memory map for virtual memory.
///
/// The resulting map will be structured as follows:
/// - All non conventional (reserved) blocks will stay at the same address (`virtual = physical`)
/// - All conventional blocks get grouped together and build a single block starting at (`max(physical+pages*page_size)`)
pub fn buildVirtualMap(mmap: *uefi.tables.MemoryMapSlice, alloc: Allocator) uefi.Error!VirtualMapData {
    const info = &mmap.info;
    const desc_size = info.descriptor_size;
    const vmap_bytes: []align(8) u8 = alloc.alignedAlloc(u8, std.mem.Alignment.fromByteUnits(8), info.len * desc_size) catch return uefi.Error.OutOfResources;
    const vmap_ptr: [*]align(8) u8 = vmap_bytes.ptr;
    var virtual_map_item: usize = 0;

    const convential_start = findMaxReservedAddress(mmap);
    var current_base = convential_start;

    var iter = mmap.iterator();
    while (iter.next()) |desc| {
        // if(!desc.attribute.memory_runtime) continue; why is this here?
        if (desc.type == .conventional_memory) {
            desc.virtual_start = current_base;
            current_base += desc.number_of_pages * 4096;
        } else {
            desc.virtual_start = desc.physical_start;
        }

        const offset = virtual_map_item * desc_size;
        // ptrCast SAFETY: valid offset (multiple of descriptor_size) from base
        const virt_element: *MemoryDescriptor = @ptrCast(@alignCast(vmap_ptr[offset..]));
        virt_element.* = desc.*;
        virtual_map_item += 1;
    }

    const vmap = uefi.tables.MemoryMapSlice{
        .ptr = vmap_ptr,
        .info = info.*,
    };

    return .{ .vmap = vmap, .conventional_region = MemoryRegions{
        .usable_memory_start = convential_start,
        .usable_memory_end = current_base,
    } };
}

fn findMaxReservedAddress(mmap: *uefi.tables.MemoryMapSlice) usize {
    var it = mmap.iterator();
    var max: usize = 0;
    while (it.next()) |mem_desc| {
        if (mem_desc.type != .conventional_memory) {
            max = @max(max, mem_desc.physical_start + mem_desc.number_of_pages * 4096);
        }
    }
    return max;
}

/// Update pointers given virtual map
///
/// `change_pointers` should be a tuple of `**anytype`. This will modify the inner
/// `*anytype` to point to the new virtual location
pub fn updatePointers(mmap: *uefi.tables.MemoryMapSlice, change_pointers: anytype) void {
    const cp_type_info = @typeInfo(@TypeOf(change_pointers));
    switch (cp_type_info) {
        .@"struct" => |cp_struct| blk: {
            if (!cp_struct.is_tuple) {
                break :blk;
            }
            var iter = mmap.iterator();
            while (iter.next()) |desc| {
                if (!desc.attribute.memory_runtime) continue;
                const physical_start = desc.physical_start;
                const physical_size = desc.number_of_pages * 4096;
                const physical_end = physical_start + physical_size;

                inline for (cp_struct.fields) |field| {
                    const field_info = @typeInfo(field.type);
                    if (field_info != .pointer) {
                        @compileError("change_pointer doesn't have corret type. Expected '**any'");
                    }
                    const ifield_info = @typeInfo(field_info.pointer.child);

                    if (ifield_info != .pointer) {
                        @compileError("change_pointer doesn't have corret type. Expected '**any'");
                    }
                    const PT = field_info.pointer.child;
                    const val: *PT = @field(change_pointers, field.name);
                    const deref_val: PT = val.*; // Literal dereference so that compiler does not do weird inference
                    const val_address = @intFromPtr(deref_val);
                    if (physical_start <= val_address and val_address < physical_end) {
                        const new_ptr: PT = @ptrFromInt(val_address - physical_start + desc.virtual_start);
                        val.* = new_ptr;
                    }
                }
            }
            return;
        },
        else => {},
    }
    @compileError("Expected change_pointers to be a tuple struct!");
}
