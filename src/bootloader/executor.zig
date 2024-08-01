const std = @import("std");
const uefi = std.os.uefi;

const Status = uefi.Status;
const EfiError = Status.EfiError;

const loaderMod = @import("./loader.zig");
const KernelData = loaderMod.KernelData;

const log = @import("./log.zig");

const graphics = @import("shared").graphics;
const GOPWrapper = graphics.GOPWrapper;

const EntryType = *const fn([*]const loaderMod.Reserve, usize, GOPWrapper) callconv(.C) void;

const memory = @import("./memory.zig");

fn exitBootServices(boot: *uefi.tables.BootServices) Status {
    const memory_info_raw = memory.getMemoryInfo(boot);
    if(memory_info_raw == .err) {
        return memory_info_raw.err;
    }
    const memory_info = memory_info_raw.ok;
    const status = boot.exitBootServices(uefi.handle, memory_info.map_key);
    if(status != .Success) {
        _ = boot.freePool(@ptrCast(@constCast(memory_info.memory_map.ptr)));
    }

    return status;
}

pub fn startKernel(boot: *uefi.tables.BootServices, data: *KernelData, gop_wrapper: GOPWrapper) Status {
    const reserves = data.reserves.toOwnedSlice() catch return Status.Aborted;
    const status = exitBootServices(boot);
    if(status != .Success) {
        return status;
    }

    const entry: EntryType = @ptrFromInt(data.kernel_image_entry);
    entry(reserves.ptr, reserves.len, gop_wrapper);

    while (true) {}
    return EfiError.LoadError;
}