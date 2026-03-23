const std = @import("std");
const uefi = std.os.uefi;
const Io = std.Io;
const Self = @This();

file: *uefi.protocol.File,
interface: Io.Reader,

pub fn init(file: *uefi.protocol.File, buffer: []u8) Self {
    return .{
        .file = file,
        .interface = initInterface(buffer)
    };
}

pub fn initInterface(buffer: []u8) Io.Reader {
    return .{
        .vtable = &.{
            .stream = stream,
        },
        .buffer = buffer,
        .seek = 0,
        .end = 0,
    };
}

fn stream(r: *Io.Reader, w: *Io.Writer, limit: Io.Limit) Io.Reader.StreamError!usize {
    const uefi_reader: *Self = @fieldParentPtr("interface", r);
    const dest = limit.slice(try w.writableSliceGreedy(1));
    const n = uefi_reader.file.read(dest) catch return error.ReadFailed;
    w.advance(n);
    return n;
}

pub fn seekTo(s: *Self, offset: usize) !void {
    return s.file.setPosition(offset);
}