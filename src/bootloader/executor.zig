const std = @import("std");
const uefi = std.os.uefi;

const Status = uefi.Status;
const EfiError = Status.EfiError;

const loaderMod = @import("./loader.zig");
const KernelData = loaderMod.KernelData;

const log = @import("./log.zig");

const memory = @import("./memory/index.zig");
const MemoryInfo = memory.MemoryInfo;
const VirtualMapData = memory.VirtualMapData;

const sharedModule = @import("shared");
const MemoryRegions = sharedModule.memory.MemoryRegions;
const GOPWrapper = sharedModule.graphics.GOPWrapper;
const EntryType = sharedModule.entry.EntryType;

fn exitBootServices(boot: *uefi.tables.BootServices, map_key: usize) Status {
    return boot.exitBootServices(uefi.handle, map_key);
}

fn mapToVirtualMemory(memory_info: *MemoryInfo, allocator: std.mem.Allocator, change_pointers: anytype) !VirtualMapData {
    const memory_regions = memory.buildVirtualMap(memory_info,allocator);
    memory.updatePointers(memory_info, change_pointers);
    return memory_regions;
}


pub fn startKernel(boot: *uefi.tables.BootServices, allocator: std.mem.Allocator, data: *KernelData, gop_wrapper: *GOPWrapper) Status {
    const memory_info_raw = memory.getMemoryInfo(boot, allocator);
    if(memory_info_raw == .err) {
        memory_info_raw.printError();
        return memory_info_raw.err;
    }
    var memory_info = memory_info_raw.ok;

    var entry = data.kernel_image_entry;

    var frame_buffer_address = gop_wrapper.framebuffer;
    const pointers_to_change = .{&entry, &frame_buffer_address};
    const vmap_data = mapToVirtualMemory(&memory_info, allocator, pointers_to_change) catch return Status.OutOfResources;

    var status = exitBootServices(boot, memory_info.map_key);
    if(status != .Success) {
        log.putslnErr("Failed to exit boot services");
        return status;
    }

    const vmap = vmap_data.virtual_map;
    
    status = uefi.system_table.runtime_services.setVirtualAddressMap(vmap.memory_map_size, vmap.descriptor_size, vmap.descriptor_version, vmap.memory_map);
    
    if(status != .Success) {
        for(0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, 0, .{.red = 255});
        }
        return status;
    }

    entry(uefi.system_table, vmap_data.conventional_region, gop_wrapper);

    return Status.LoadError;
}