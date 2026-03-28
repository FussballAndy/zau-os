const memory_info = @import("./memory_info.zig");

pub const getMemoryInfo = memory_info.getMemoryInfo;
pub const buildSimpleMMap = @import("simple_map.zig").buildSimpleMMap;