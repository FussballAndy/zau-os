const std = @import("std");

pub const MemoryRegions = extern struct {
    usable_memory_start: usize,
    usable_memory_end: usize,
};

pub const SimpleDescriptor = struct {
    usable: bool,
    start: u64,
    pages: u64,
    attribute: std.os.uefi.tables.MemoryDescriptorAttribute,
};