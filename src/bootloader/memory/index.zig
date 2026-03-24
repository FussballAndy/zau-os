const virtual_map = @import("./virtual_map.zig");
const memory_info = @import("./memory_info.zig");
const structs = @import("./structs.zig");

pub const VirtualMapData = structs.VirtualMapData;
pub const buildVirtualMap = virtual_map.buildVirtualMap;
pub const updatePointers = virtual_map.updatePointers;
pub const getMemoryInfo = memory_info.getMemoryInfo;
