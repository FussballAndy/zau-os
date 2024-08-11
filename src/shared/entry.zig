pub const Reserve = extern struct {
    begin: usize,
    end: usize,
};

const GOPWrapper = @import("./graphics_wrapper.zig").GOPWrapper;

pub const EntryType = *const fn([*]const Reserve, usize, GOPWrapper) callconv(.C) void;