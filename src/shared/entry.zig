pub const MemoryRegion = extern struct {
    start: usize,
    pages: usize,
};

const GOPWrapper = @import("./graphics_wrapper.zig").GOPWrapper;

pub const EntryType = *const fn([*]const MemoryRegion, usize, *GOPWrapper) callconv(.C) void;