const sharedModule = @import("shared");
const graphics = sharedModule.graphics;
const entry = sharedModule.entry;
const GOPWrapper = graphics.GOPWrapper;


export fn _start(regions_ptr: [*]const entry.MemoryRegion, regions_len: usize, gop_wrapper: *GOPWrapper) callconv(.C) void {
    const regions = regions_ptr[0..regions_len];
    _ = regions;
    for(0..gop_wrapper.info.horizontal_resolution) |x| {
        for(0..gop_wrapper.info.horizontal_resolution) |y| {
            gop_wrapper.setPixel(x, y, .{.red = 255, .green = 255, .blue = 255});
        }
    }
}

comptime {
    if(@TypeOf(&_start) != entry.EntryType) {
        @compileError("_start of kernel doesn't have fitting type. See shared.entry.EntryType");
    }
}