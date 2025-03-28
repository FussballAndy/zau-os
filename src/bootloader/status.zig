const std = @import("std");
const uefi = std.os.uefi;

const log = @import("./log.zig");

const high_bit = 1 << @typeInfo(usize).int.bits - 1;

pub fn isError(status: uefi.Status) bool {
    return @intFromEnum(status) & high_bit != 0;
}

pub fn UefiResult(E: type) type {
    return union(enum) {
        ok: E,
        err: uefi.Status,
    };
}

test isError {
    try std.testing.expect(isError(uefi.Status.Unsupported));
}