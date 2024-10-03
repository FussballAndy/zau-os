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

const console = @import("./console.zig");
const exceptions = @import("./exception.zig");

pub var global_allocator: Allocator = undefined;

export fn _start(sys_table: *SystemTable, memory_regions: memory.MemoryRegions, gop_wrapper: *GOPWrapper) callconv(.C) noreturn {
    _ = sys_table;

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

    const screenWriter = console.setupConsole(gop_wrapper);

    screenWriter.print("Welcome from the kernel!\n", .{}) catch paintScreen(gop_wrapper, .{.red = 255});

    safeStart(screenWriter) catch |err| {
        console.reset();
        paintScreen(gop_wrapper, .{});
        // Catch in a catch seems cursed, also bsod
        screenWriter.print("Encountered following error: {!}", .{err}) catch paintScreen(gop_wrapper, .{.blue = 255});
    };

    while (true) {}
}

fn safeStart(screenWriter: console.WriterType) !void {
    const cur_el = exceptions.getCurrentEl();

    try screenWriter.print("Current EL: {}\n", .{cur_el});

    try screenWriter.print("abcdefghijklmnopqrstuvxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\n", .{});

    return error.YouAreAPoopyHead;
}

pub fn paintScreen(gop_wrapper: *GOPWrapper, color: graphics.Color) void {
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