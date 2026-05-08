const std = @import("std");

// https://developer.arm.com/documentation/ddi0601/2025-12/AArch64-Registers/SCTLR-EL1--System-Control-Register--EL1-
pub const SCTLR_EL1 = packed struct(u64) {
    m: bool,
    _u3: bool,
    c: bool,
    _u2: u22,
    ee: bool,
    _u1: u38,

    pub fn read() @This() {
        return asm ("mrs %[res], SCTLR_EL1"
        : [res] "=r" (-> @This()),
        );
    }

    pub fn write(self: @This()) void {
        asm volatile ("msr SCTLR_EL1, %[val]"
        :
        : [val] "r" (self)
        );
    }
};

pub const TCR_EL1 = packed struct(u64) {
    t0sz: u6,
    _res0: bool,
    epd0: bool,
    irgn0: u2,
    orgn0: u2,
    sh0: u2,
    tg0: u2,
    t1sz: u6,
    a1: bool,
    epd1: bool,
    irgn1: u2,
    orgn1: u2,
    sh1: u2,
    tg1: u2,
    ips: u3,
    _u1: u29,

    pub fn read() @This() {
        return asm ("mrs %[res], TCR_EL1"
        : [res] "=r" (-> @This()),
        );
    }

    pub fn write(self: @This()) void {
        asm volatile ("msr TCR_EL1, %[val]"
        :
        : [val] "r" (self)
        );
    }
};

pub const MAIR_EL1 = packed struct(u64) {
    _attrs: u64,

    pub fn set_attr(self: *@This(), index: u8, value: u8) void {
        const raw: [*]u8 = @ptrCast(self);
        raw[index] = value;
    }

    pub fn read() @This() {
        return asm ("mrs %[res], MAIR_EL1"
        : [res] "=r" (-> @This()),
        );
    }

    pub fn write(self: @This()) void {
        asm volatile ("msr MAIR_EL1, %[val]"
        :
        : [val] "r" (self)
        );
    }
};

pub const TTBR0_EL1 = packed struct(u64) {
    cnp: bool,
    skl: u2,
    _res0: u2,
    baddr: u43,
    asid: u16,

    pub fn read() @This() {
        return asm ("mrs %[res], TTBR0_EL1"
        : [res] "=r" (-> @This()),
        );
    }

    pub fn write(self: @This()) void {
        asm volatile ("msr TTBR0_EL1, %[val]"
        : 
        : [val] "r" (self)
        );
    }
};

pub const TTBR1_EL1 = packed struct(u64) {
    cnp: bool,
    skl: u2,
    _res0: u2,
    baddr: u43,
    asid: u16,

    pub fn read() @This() {
        return asm ("mrs %[res], TTBR1_EL1"
        : [res] "=r" (-> @This()),
        );
    }

    pub fn write(self: @This()) void {
        asm volatile ("msr TTBR1_EL1, %[val]"
        :
        : [val] "r" (self)
        );
    }
};