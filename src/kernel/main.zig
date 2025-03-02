const sharedModule = @import("shared");
const graphics = sharedModule.graphics;
const entry = sharedModule.entry;
const memory = sharedModule.memory;
const GOPWrapper = graphics.GOPWrapper;
const std = @import("std");
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const Allocator = std.mem.Allocator;
const uefi = std.os.uefi;
const SystemTable = uefi.tables.SystemTable;

const Console = @import("./console.zig").Console;
const exceptions = @import("./exception.zig");

pub var global_allocator: Allocator = undefined;
var global_gop: *GOPWrapper = undefined;

export fn _start(sys_table: *SystemTable, memory_regions: memory.MemoryRegions, gop_wrapper: *GOPWrapper) callconv(.C) noreturn {
    _ = sys_table;
    global_gop = gop_wrapper;

    const buffer_ptr: [*]u8 = @ptrFromInt(memory_regions.usable_memory_start);
    const buffer_len = memory_regions.usable_memory_end - memory_regions.usable_memory_start;
    const buffer = buffer_ptr[0..buffer_len];
    var fba = FixedBufferAllocator.init(buffer);
    const fba_allocator = fba.allocator();
    // Arena Allocator works pretty similar to the implementation of malloc (and co.) within GNU's libc
    var arena = std.heap.ArenaAllocator.init(fba_allocator);
    defer arena.deinit();
    global_allocator = arena.allocator();

    paintScreen(gop_wrapper, .{});

    var screenWriter = Console.new(gop_wrapper);

    screenWriter.print("Welcome from the kernel!\n", .{}) catch paintScreen(gop_wrapper, .{.red = 255});

    safeStart(&screenWriter) catch |err| {
        screenWriter.reset();
        paintScreen(gop_wrapper, .{});
        // Catch in a catch seems cursed, also bsod
        // @errorName seems to cause ub. idk why but for now we just stick to this instead of
        // {s} and @errorName(err)
        screenWriter.print("Encountered following error: {}\n", .{err}) catch paintScreen(gop_wrapper, .{.blue = 255});
    };

    while (true) {}
}

fn safeStart(screenWriter: *Console) !void {
    const cur_el = exceptions.getCurrentEl();

    try screenWriter.print("Current EL: {}\n", .{cur_el});

    const cur_spsel = exceptions.getSPSel();

    try screenWriter.print("Current SPSel: {}\n", .{cur_spsel});

    try screenWriter.print("abcdefghijklmnopqrstuvxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\n", .{});
}

pub fn paintScreen(gop_wrapper: *GOPWrapper, color: graphics.Color) void {
    for(0..gop_wrapper.info.vertical_resolution) |y| {
        for(0..gop_wrapper.info.horizontal_resolution) |x| {
            gop_wrapper.setPixel(x, y, color);
        }
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;
    @setCold(true);
    paintScreen(global_gop, .{.blue = 255, .green = 255});
    var errorWriter = Console.new(global_gop);
    errorWriter.writer().writeAll(msg) catch {};
    while (true) {
        @breakpoint();
    }
}

comptime {
    if(@TypeOf(&_start) != entry.EntryType) {
        @compileError("_start of kernel doesn't have fitting type. See shared.entry.EntryType");
    }
}