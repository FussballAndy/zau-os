const sharedModule = @import("shared");
const graphics = sharedModule.graphics;
const entry = sharedModule.entry;
const GOPWrapper = graphics.GOPWrapper;


export fn _start(reserves: [*]const entry.Reserve, reserve_size: usize, gop_wrapper_raw: GOPWrapper) callconv(.C) void {
    _ = reserves;
    _ = reserve_size;
    var gop_wrapper = gop_wrapper_raw;
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