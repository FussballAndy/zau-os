const std = @import("std");
const uefi = std.os.uefi;

const Status = uefi.Status;
const EfiError = Status.EfiError;

const loaderMod = @import("./loader.zig");
const KernelData = loaderMod.KernelData;

const log = @import("./log.zig");

const sharedModule = @import("shared");
const GOPWrapper = sharedModule.graphics.GOPWrapper;
const EntryType = sharedModule.entry.EntryType;

const memory = @import("./memory.zig");

fn exitBootServices(boot: *uefi.tables.BootServices, map_key: usize) Status {
    return boot.exitBootServices(uefi.handle, map_key);
}

fn getUsableMemoryAreas(raw_it: memory.MemoryMapIterator) ![]sharedModule.entry.MemoryRegion {
    var it = raw_it;
    var regions = std.ArrayList(sharedModule.entry.MemoryRegion).init(uefi.pool_allocator);
    while (it.next()) |mem_desc| {
        switch (mem_desc.type) {
            .ConventionalMemory, .BootServicesCode, .BootServicesData => {
                try regions.append(sharedModule.entry.MemoryRegion {
                    .start = mem_desc.physical_start,
                    .pages = mem_desc.number_of_pages,
                });
            },
            else => {}
        }
    }
    return regions.toOwnedSlice();
}

pub fn startKernel(boot: *uefi.tables.BootServices, data: *KernelData, gop_wrapper: *GOPWrapper) Status {
    const memory_info_raw = memory.getMemoryInfo(boot);
    if(memory_info_raw == .err) {
        memory_info_raw.printError();
        return memory_info_raw.err;
    }
    const memory_info = memory_info_raw.ok;


    const regions = getUsableMemoryAreas(memory_info.memoryMapIterator()) catch return Status.Aborted;
    const status = exitBootServices(boot, memory_info.map_key);
    if(status != .Success) {
        // ptrCast SAFETY: [*]const MemoryDescriptor -> [*]MemoryDescriptor -> [*]u8
        _ = boot.freePool(@ptrCast(@constCast(memory_info.memory_map)));
        return status;
    }

    const entry = data.kernel_image_entry;
    entry(regions.ptr, regions.len, gop_wrapper);

    while (true) {}
    return Status.LoadError;
}