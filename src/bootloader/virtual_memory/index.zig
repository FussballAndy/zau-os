const map_import = @import("./map.zig");
pub const buildVirtualMap = map_import.buildVirtualMap;
pub const VirtualMapData = map_import.VirtualMapData;

const mem_structs = @import("../memory_info.zig");
const MemoryInfo = mem_structs.MemoryInfo;

pub fn updatePointers(memory_info: *MemoryInfo, change_pointers: anytype) void {
    var mmap_iter = memory_info.memoryMapIterator();
    while (mmap_iter.next()) |mem_desc| {
        if(!mem_desc.attribute.memory_runtime) continue;
        const physical_start = mem_desc.physical_start;
        const physical_size = mem_desc.number_of_pages * 4096;
        const physical_end = physical_start + physical_size;

        const cp_type_info = @typeInfo(@TypeOf(change_pointers));
        if(cp_type_info == .Struct and cp_type_info.Struct.is_tuple) {
            inline for (cp_type_info.Struct.fields) |field| {
                const field_info = @typeInfo(field.type);
                if(field_info != .Pointer) {
                    @compileError("change_pointer doesn't have corret type. Expected '**any'");
                }
                const ifield_info = @typeInfo(field_info.Pointer.child);
                
                if(ifield_info != .Pointer) {
                    @compileError("change_pointer doesn't have corret type. Expected '**any'");
                }
                const PT = field_info.Pointer.child;
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