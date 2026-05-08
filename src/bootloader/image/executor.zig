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

const reg = @import("../aarch64/registers.zig");
const mair = @import("../aarch64/mair.zig");
const pt = @import("../aarch64/page_table.zig");

fn debug_print_mmap(mmap: *const uefi.tables.MemoryMapSlice) void {
    var iter = mmap.iterator();
    while (iter.next()) |desc| {
        log.print("type: {f} phy: 0x{X} #: {} virt: 0x{X} rt: {}\r\n", .{ desc.type, desc.physical_start, desc.number_of_pages, desc.virtual_start, desc.attribute.memory_runtime });
    }
    log.print("\r\n", .{});
}

fn copyMemoryMap(mmap: *const uefi.tables.MemoryMapSlice, alloc: std.mem.Allocator) uefi.Error!uefi.tables.MemoryMapSlice {
    const len = mmap.info.descriptor_size * mmap.info.len;
    const copied_desc = alloc.alignedAlloc(u8, .of(uefi.tables.MemoryDescriptor), len) catch return uefi.Error.OutOfResources;
    @memcpy(copied_desc, mmap.ptr[0..len]);
    var mmap2 = mmap.*;
    mmap2.ptr = copied_desc.ptr;
    return mmap2;
}

pub fn startKernel(boot: *uefi.tables.BootServices, allocator: std.mem.Allocator, data: *KernelData, gop_wrapper: *GOPWrapper) uefi.Error!void {
    const pc = asm (
        "adr %[ret], ."
        : [ret] "=r" (-> usize)
    );
    log.print("pc: 0x{X}\r\n", .{pc});
    var mmap = try memory.getMemoryInfo(boot, allocator);

    const smap = try memory.buildSimpleMMap(&mmap, allocator);

    const vmap = try copyMemoryMap(&mmap, allocator);
    var iter = vmap.iterator();
    while(iter.next()) |desc| {
        if(desc.type == .vendor_start) {
            desc.virtual_start = data.virtual_start;
        } else {
            desc.virtual_start = desc.physical_start;
        }
    }

    // TODO: map kernel virtually

    boot.exitBootServices(uefi.handle, mmap.info.key) catch |err| {
        log.putslnErr("Failed to exit boot services");
        return err;
    };

    mair.setupMAIR();
    pt.setupIdentityMap(allocator, data.physical_start) catch {
        for (0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, 1, .{.red = 255});
        }
        while(true) {}
    };
    pt.setupTCR();

    while(true) {}

    pt.enableMMU();

    for (0..gop_wrapper.info.vertical_resolution) |y| {
        for (0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, y, .{});
        }
    }

    

    uefi.system_table.runtime_services.setVirtualAddressMap(vmap) catch {
        for (0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, 1, .{.red = 255});
        }
        while(true) {}
    };

    const entry = data.kernel_image_entry;
    entry(uefi.system_table, smap.ptr, smap.len, gop_wrapper);

    return uefi.Error.LoadError;
}
