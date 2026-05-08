const std = @import("std");
const reg = @import("registers.zig");
const ins = @import("instructions.zig");

pub const MT_NORMAL: u8 = 0;
pub const MT_NORMAL_NO_CACHING: u8 = 1;
pub const MT_DEVICE_nGnRnE: u8 = 2;
pub const MT_DEVICE_nGnRE: u8 = 3;

const MAIR_ATTR_NORMAL: u8 = 0xff;
const MAIR_ATTR_NORMAL_NO_CACHING: u8 = 0x44;
const MAIR_ATTR_DEVICE_nGnRnE: u8 = 0x00;
const MAIR_ATTR_DEVICE_nGnRE: u8 = 0x04;

pub fn setupMAIR() void {
    var mair = std.mem.zeroes(reg.MAIR_EL1);
    mair.set_attr(MT_NORMAL, MAIR_ATTR_NORMAL);
    mair.set_attr(MT_NORMAL_NO_CACHING, MAIR_ATTR_NORMAL_NO_CACHING);
    mair.set_attr(MT_DEVICE_nGnRnE, MAIR_ATTR_DEVICE_nGnRnE);
    mair.set_attr(MT_DEVICE_nGnRE, MAIR_ATTR_DEVICE_nGnRE);
    mair.write();
    // ins.synchronizeInstructions();
}