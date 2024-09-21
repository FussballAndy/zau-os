const sharedModule = @import("shared");
const graphics = sharedModule.graphics;
const entry = sharedModule.entry;
const memory = sharedModule.memory;
const GOPWrapper = graphics.GOPWrapper;
const uefi = @import("std").os.uefi;
const SystemTable = uefi.tables.SystemTable;


export fn _start(sys_table: *SystemTable, memory_regions: memory.MemoryRegions, gop_wrapper: *GOPWrapper) callconv(.C) void {
    _ = sys_table;
    _ = memory_regions;
    paintScreen(gop_wrapper, .{.red = 255, .green = 255, .blue = 255});
}

fn paintScreen(gop_wrapper: *GOPWrapper, color: graphics.Color) void {
    for(0..gop_wrapper.info.vertical_resolution) |y| {
        for(0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, y, color);
        }
    }
}

comptime {
    if(@TypeOf(&_start) != entry.EntryType) {
        @compileError("_start of kernel doesn't have fitting type. See shared.entry.EntryType");
    }
}