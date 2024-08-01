const graphics = @import("shared").graphics;
const GOPWrapper = graphics.GOPWrapper;


pub const Reserve = extern struct {
    name: [*:0]const u8,
    begin: usize,
    end: usize,
};

export fn _start(reserves: [*]const Reserve, reserve_size: usize, gop_wrapper_raw: GOPWrapper) callconv(.C) void {
    _ = reserves;
    _ = reserve_size;
    var gop_wrapper = gop_wrapper_raw;
    for(0..gop_wrapper.info.horizontal_resolution) |x| {
        for(0..gop_wrapper.info.horizontal_resolution) |y| {
            gop_wrapper.setPixel(x, y, .{.red = 255, .green = 255, .blue = 255});
        }
    }
}