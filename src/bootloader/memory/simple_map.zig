const std = @import("std");
const uefi = std.os.uefi;
const MemoryDescriptorAttribute = uefi.tables.MemoryDescriptorAttribute;
const Allocator = std.mem.Allocator;

const SimpleDescriptor = @import("shared").memory.SimpleDescriptor;

const log = @import("../log.zig");

fn isUsable(ty: uefi.tables.MemoryType) bool {
    return ty == .boot_services_code or ty == .boot_services_data or ty == .conventional_memory;
}

fn lessThanSMap(_: void, a: SimpleDescriptor, b: SimpleDescriptor) bool {
    return a.start < b.start;
}

pub fn buildSimpleMMap(mmap: *uefi.tables.MemoryMapSlice, alloc: Allocator) uefi.Error![]SimpleDescriptor {
    var smap = alloc.alloc(SimpleDescriptor, mmap.info.len) catch return uefi.Error.OutOfResources;
    // probably equivalent to zeroing, but just to be sure.
    @memset(smap, SimpleDescriptor{.usable = false, .start = 0, .pages = 0, .attribute = std.mem.zeroes(MemoryDescriptorAttribute)});
    var smap_item: usize = 0;

    var iter = mmap.iterator();
    while(iter.next()) |desc| {
        smap[smap_item] = .{
            .usable = isUsable(desc.type),
            .start = desc.physical_start,
            .pages = desc.number_of_pages,
            .attribute = desc.attribute,
        };
        smap_item += 1;
    }
    std.mem.sort(SimpleDescriptor, smap, {}, lessThanSMap);

    var i = smap.len - 1;
    while(i > 1) : (i -= 1) {
        const cur = &smap[i];
        const prev = &smap[i-1];
        const prev_end = prev.start + prev.pages * 4096;
        if(cur.start == prev_end and cur.usable == prev.usable) {
            // merge cur and next
            prev.pages += cur.pages;
            cur.pages = 0;
        }
    }

    i = 0;
    var count: usize = 0;
    while(i < smap.len) : (i += 1) {
        if(smap[i].pages > 0) {
            // SAFETY: i will always be >= count, thus we do not override necessary data, but all relevant items will still be present.
            smap[count] = smap[i];
            count += 1;
        }
    }
    smap.len = count;
    _ = alloc.resize(smap, count);
    
    return smap;
}