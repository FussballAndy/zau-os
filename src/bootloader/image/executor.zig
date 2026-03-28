const std = @import("std");
const uefi = std.os.uefi;

const Status = uefi.Status;

const KernelData = @import("./loader.zig").KernelData;

const log = @import("../log.zig");

const memory = @import("../memory/index.zig");

const sharedModule = @import("shared");
const MemoryRegions = sharedModule.memory.MemoryRegions;
const GOPWrapper = sharedModule.graphics.GOPWrapper;
const EntryType = sharedModule.entry.EntryType;

fn debug_print_mmap(mmap: *const uefi.tables.MemoryMapSlice) void {
    var iter = mmap.iterator();
    while (iter.next()) |desc| {
        log.print("type: {f} phy: 0x{X} #: {} virt: 0x{X} rt: {}\r\n", .{ desc.type, desc.physical_start, desc.number_of_pages, desc.virtual_start, desc.attribute.memory_runtime });
    }
    log.print("\r\n", .{});
}

pub fn startKernel(boot: *uefi.tables.BootServices, allocator: std.mem.Allocator, data: *KernelData, gop_wrapper: *GOPWrapper) uefi.Error!void {
    var mmap = try memory.getMemoryInfo(boot, allocator);

    const smap = try memory.buildSimpleMMap(&mmap, allocator);

    boot.exitBootServices(uefi.handle, mmap.info.key) catch |err| {
        log.putslnErr("Failed to exit boot services");
        return err;
    };

    const entry = data.kernel_image_entry;
    entry(uefi.system_table, smap.ptr, smap.len, gop_wrapper);

    return uefi.Error.LoadError;
}
