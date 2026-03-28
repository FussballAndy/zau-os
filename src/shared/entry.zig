const memory = @import("./memory.zig");
const uefi = @import("std").os.uefi;
const SystemTable = uefi.tables.SystemTable;

const GOPWrapper = @import("./graphics_wrapper.zig").GOPWrapper;

pub const EntryType = *const fn (*SystemTable, [*]memory.SimpleDescriptor, usize, *GOPWrapper) callconv(.c) noreturn;
