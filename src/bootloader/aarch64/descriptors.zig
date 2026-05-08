const std = @import("std");

fn bitmaskOf(comptime T: type, comptime field: []const u8) u64 {
    return comptime blk: {
        const field_ty: type = @FieldType(T, field);
        const max = std.math.maxInt(field_ty);
        break :blk max << @bitOffsetOf(T, field);
    };
}

inline fn genericFromPointer(comptime T: type, next: *const anyopaque, comptime id: u2) T {
    const addr = @intFromPtr(next);
    const addr_masked = addr & bitmaskOf(T, "addr");
    return @bitCast(addr_masked | id);
}

inline fn genericGetPointer(comptime T: type, s: T) *const anyopaque {
    const num = @as(u64, s);
    const masked = num & bitmaskOf(T, "addr");
    return @ptrFromInt(masked);
}

pub const TableAttributes = packed struct(u5) {
    pxn_table: bool,
    xn_table: bool,
    ap_table: u2,
    ns_table: bool,
};

pub const TableDescriptor = packed struct(u64) {
    _id: u2 = 0b11,
    _ignored: u10,
    addr: u36,
    _res0: u3,
    _ignored2: u8,
    attributes: TableAttributes,

    pub fn fromPointer(next: *const anyopaque) @This() {
        return genericFromPointer(@This(), next, 0b11);
    }

    pub fn getPointer(s: @This()) *anyopaque {
        return genericGetPointer(@This(), s);
    }
};

pub const LowerAttributes = packed struct(u10) {
    attr_index: u3,
    ns: bool,
    ap: u2,
    sh: u2,
    af: bool,
    ng_or_nse: bool,
};

pub const UpperAttributes = packed struct(u14) {
    gp: bool,
    dbm: bool,
    contiguous: bool,
    pxn: bool,
    xn: bool,
    _ignored: u4,
    pbha: u4,
    amec: bool,
};

pub const BlockDescriptor = packed struct(u64) {
    _id: u2 = 0b01,
    lower_attributes: LowerAttributes,
    _res1: u4,
    nT: bool,
    _res2: u4,
    addr: u27,
    _res3: u2,
    upper_attributes: UpperAttributes,

    pub fn fromPointer(next: *const anyopaque) @This() {
        return genericFromPointer(@This(), next, 0b01);
    }

    pub fn getPointer(s: @This()) *anyopaque {
        return genericGetPointer(@This(), s);
    }
};

pub const PageDescriptor = packed struct(u64) {
    _id: u2 = 0b11,
    lower_attributes: LowerAttributes,
    addr: u36,
    _res1: u2,
    upper_attributes: UpperAttributes,

    pub fn fromPointer(next: *const anyopaque) @This() {
        return genericFromPointer(@This(), next, 0b11);
    }

    pub fn getPointer(s: @This()) *anyopaque {
        return genericGetPointer(@This(), s);
    }
};