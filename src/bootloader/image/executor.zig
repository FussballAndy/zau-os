const std = @import("std");
const uefi = std.os.uefi;

const Status = uefi.Status;

const KernelData = @import("./loader.zig").KernelData;

const log = @import("../log.zig");

const memory = @import("../memory/index.zig");
const MemoryInfo = memory.MemoryInfo;
const VirtualMapData = memory.VirtualMapData;

const sharedModule = @import("shared");
const MemoryRegions = sharedModule.memory.MemoryRegions;
const GOPWrapper = sharedModule.graphics.GOPWrapper;
const EntryType = sharedModule.entry.EntryType;

fn exitBootServices(boot: *uefi.tables.BootServices, map_key: uefi.tables.MemoryMapKey) uefi.Error!void {
    return boot.exitBootServices(uefi.handle, map_key);
}

fn mapToVirtualMemory(memory_info: *MemoryInfo, allocator: std.mem.Allocator, change_pointers: anytype) uefi.Error!VirtualMapData {
    const memory_regions = try memory.buildVirtualMap(memory_info,allocator);
    memory.updatePointers(memory_info, change_pointers);
    return memory_regions;
}


pub fn startKernel(boot: *uefi.tables.BootServices, allocator: std.mem.Allocator, data: *KernelData, gop_wrapper: *GOPWrapper) uefi.Error!void {
    var memory_info = try memory.getMemoryInfo(boot, allocator);

    var entry = data.kernel_image_entry;

    var frame_buffer_address = gop_wrapper.framebuffer;
    const pointers_to_change = .{&entry, &frame_buffer_address};
    const vmap_data = mapToVirtualMemory(&memory_info, allocator, pointers_to_change) catch return Status.out_of_resources.err();

    exitBootServices(boot, memory_info.map_key) catch |err| {
        log.putslnErr("Failed to exit boot services");
        return err;
    };

    const vmap = vmap_data.virtual_map;
    
    const status = uefi.system_table.runtime_services._setVirtualAddressMap(vmap.memory_map_size, vmap.descriptor_size, vmap.descriptor_version, @ptrCast(vmap.memory_map));
    if(status != .success) {
        for(0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, 0, .{.red = 255});
        }
        try status.err();
    }

    entry(uefi.system_table, vmap_data.conventional_region, gop_wrapper);

    return uefi.Error.LoadError;
}