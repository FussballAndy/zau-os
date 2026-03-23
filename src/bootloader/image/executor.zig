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

fn mapToVirtualMemory(mmap: *uefi.tables.MemoryMapSlice, allocator: std.mem.Allocator, change_pointers: anytype) uefi.Error!VirtualMapData {
    const memory_regions = try memory.buildVirtualMap(mmap,allocator);
    memory.updatePointers(mmap, change_pointers);
    return memory_regions;
}

fn debug_print_mmap(mmap: *const uefi.tables.MemoryMapSlice) void {
    var iter = mmap.iterator();
    while(iter.next()) |desc| {
        log.print("type: {f} phy: 0x{X} #: {} virt: 0x{X} rt: {}\r\n", .{desc.type, desc.physical_start, desc.number_of_pages, desc.virtual_start, desc.attribute.memory_runtime});
    }
    log.print("\r\n", .{});
}

pub fn startKernel(boot: *uefi.tables.BootServices, allocator: std.mem.Allocator, data: *KernelData, gop_wrapper: *GOPWrapper) uefi.Error!void {
    var mmap = try memory.getMemoryInfo(boot, allocator);

    log.print("key: {}\r\n", .{@intFromEnum(mmap.info.key)});

    // debug_print_mmap(&mmap);

    var entry = data.kernel_image_entry;

    var frame_buffer_address = gop_wrapper.framebuffer;
    const pointers_to_change = .{&entry, &frame_buffer_address};
    const vmap_data = mapToVirtualMemory(&mmap, allocator, pointers_to_change) catch return uefi.Error.OutOfResources;

    log.putslnErr("Setup memory map");

    // debug_print_mmap(&vmap_data.vmap);

    log.print("key: {}\r\n", .{@intFromEnum(mmap.info.key)});
    // if(true) return;

    boot.exitBootServices(uefi.handle, mmap.info.key) catch |err| {
        log.putslnErr("Failed to exit boot services");
        return err;
    };

    const vmap = vmap_data.vmap;

    uefi.system_table.runtime_services.setVirtualAddressMap(vmap) catch |err| {
        for(0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, 0, .{.red = 255});
        }
        return err;
    };
    

    entry(uefi.system_table, vmap_data.conventional_region, gop_wrapper);

    return uefi.Error.LoadError;
}